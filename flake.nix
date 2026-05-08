{
  description = "Tamagoyaki – reproducible evaluation environment";

  nixConfig = {
    extra-substituters = [ "https://dtz-circt.cachix.org" ];
    extra-trusted-public-keys = [
      "dtz-circt.cachix.org-1:PHe0okMASm5d9SD+UE0I0wptCy58IK8uNF9P3K7f+IU="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Provides prebuilt LLVM + MLIR (matching the CIRCT pin).
    circt-nix.url = "github:dtzSiFive/circt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
      circt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
        lib = pkgs.lib;

        # ---------- LLVM / MLIR (from circt-nix) ----------
        mlir = circt-nix.packages.${system}.mlir;
        libllvm = circt-nix.packages.${system}.libllvm;

        # ---------- Rival (Rust) ----------
        rustToolchain = pkgs.rust-bin.stable."1.91.0".default;

        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };

        rivalSrc = pkgs.fetchFromGitHub {
          owner = "herbie-fp";
          repo = "rival3";
          rev = "8bc5eca5079497a41d37e20a66c833080c92c0ed";
          hash = "sha256-fnIvGCaiHqCM+ANwfLSQMTNQXw4VAewXeXU8iWePx9Y=";
        };

        # rival3-ffi static C-API library + cbindgen-generated header.
        # The subcrate has its own Cargo.lock (it's a standalone workspace)
        # so we point cargoRoot/buildAndTestSubdir at it. We use system
        # GMP/MPFR instead of letting gmp-mpfr-sys vendor them, otherwise
        # the static archive would carry duplicate copies that conflict
        # with the system libs the C++ tool also links against.
        rival-ffi = rustPlatform.buildRustPackage {
          pname = "rival3-ffi";
          version = "unstable-2026-04-28";

          src = rivalSrc;

          cargoRoot = "rival3-ffi";
          buildAndTestSubdir = "rival3-ffi";

          cargoHash = "sha256-0KD5zCJotpWKooKLvLZF3sVkPJBVec5lQ4L8CNQzrJo=";

          doCheck = false;

          # Force gmp-mpfr-sys to link the system libs rather than vendor
          # GMP/MPFR sources into the archive.
          cargoBuildFlags = [
            "--features"
            "gmp-mpfr-sys/use-system-libs"
          ];

          nativeBuildInputs = with pkgs; [
            m4
            pkg-config
            rustPlatform.bindgenHook # libclang for gmp-mpfr-sys's bindgen
          ];

          buildInputs = with pkgs; [
            gmp
            mpfr
            libmpc
          ];

          # cargo's default install hook only installs binaries; for a
          # staticlib we copy it (and the header) into $out manually.
          # Build runs inside `rival3-ffi/`, so target/ is relative to it.
          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib $out/include
            cp target/*/release/librival3_ffi.a $out/lib/ 2>/dev/null || \
              cp target/release/librival3_ffi.a $out/lib/
            cp rival3-ffi/include/rival.h $out/include/
            runHook postInstall
          '';
        };

        # ---------- Main C++/MLIR build ----------
        tamagoyaki = pkgs.stdenv.mkDerivation {
          pname = "tamagoyaki";
          version = "0.1.0";
          src = lib.cleanSource ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            pkg-config
            git
            m4
            lit # llvm-lit, required by add_lit_testsuite
          ];

          buildInputs = [
            mlir.dev
            libllvm.dev
          ]
          ++ (with pkgs; [
            gmp
            mpfr
            libmpc
          ]);

          cmakeFlags = [
            "-DMLIR_DIR=${mlir.dev}/lib/cmake/mlir"
            "-DLLVM_DIR=${libllvm.dev}/lib/cmake/llvm"
            "-DLLVM_EXTERNAL_LIT=${pkgs.lit}/bin/lit"
            "-DRIVAL_PREBUILT_LIB=${rival-ffi}/lib/librival3_ffi.a"
            "-DRIVAL_PREBUILT_INCLUDE=${rival-ffi}/include"
          ];

          # The project's CMakeLists.txt has no install() rules for the
          # *-opt executables, so `cmake --install` only picks up libraries.
          # Manually copy the binaries we care about out of the build tree.
          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            for exe in tamagoyaki-opt herbie-mlir-opt cranelift-mlir-opt rover-mlir-opt; do
              if [ -x "bin/$exe" ]; then
                cp "bin/$exe" "$out/bin/$exe"
              else
                echo "warning: expected executable bin/$exe not found in build tree" >&2
              fi
            done
            runHook postInstall
          '';

          meta = with lib; {
            description = "Tamagoyaki MLIR equality saturation tool";
            platforms = platforms.unix;
          };
        };

      in
      {
        packages = {
          default = tamagoyaki;
          inherit tamagoyaki rival-ffi mlir libllvm;
        };

        devShells.default = pkgs.mkShell {
          name = "tamagoyaki-eval";
          inputsFrom = [ tamagoyaki ];

          packages = with pkgs; [
            rustToolchain
            racket-minimal
            flex
            bison
            gmp
            mpfr
            fontconfig
            cairo
            pango
            libjpeg
            libpng
            zlib
            uv
          ];

          RACKET_FFI_LIB_PATH = lib.makeLibraryPath (
            with pkgs;
            [
              stdenv.cc.cc.lib
              gmp
              mpfr
              fontconfig
              cairo
              pango
              glib
              freetype
              fribidi
              pixman
              expat
              libjpeg
              libpng
              zlib
            ]
          );

          shellHook = ''
            if [[ "$(uname)" == "Darwin" ]]; then
              export DYLD_FALLBACK_LIBRARY_PATH="$RACKET_FFI_LIB_PATH''${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
            else
              export LD_LIBRARY_PATH="$RACKET_FFI_LIB_PATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            fi

            # Don't let the system Python interfere with uv-managed envs.
            unset PYTHONPATH

            echo "tamagoyaki eval shell ready"
            echo "  uv     : $(uv --version)"
            echo "  cargo  : $(cargo --version)"
            echo "  cmake  : $(cmake --version | head -1)"
          '';
        };
      }
    );
}
