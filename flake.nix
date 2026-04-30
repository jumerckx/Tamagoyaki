{
  description = "Tamagoyaki – reproducible evaluation environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
        lib = pkgs.lib;

        # ---------- Python env via uv2nix ----------
        python = pkgs.python313;

        workspace = uv2nix.lib.workspace.loadWorkspace {
          workspaceRoot = ./.;
        };

        # Prefer wheels — critical for the MLIR wheel, which we don't
        # want Nix trying to build from source.
        pyOverlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel";
        };

        # uv2nix can't auto-pick a wheel for `mlir-wheel`: the lockfile lists
        # `py3-none-<platform>` wheels whose platform tags (e.g.
        # `macosx_12_0_arm64`, plain `linux_x86_64`) aren't recognised as
        # compatible by pyproject.nix's wheel selector. Provide it manually.
        mlirWheelOverlay = final: prev: {
          mlir-wheel =
            let
              base = "https://github.com/llvm/eudsl/releases/download/llvm";
              ver = "20260405+17ed1e6c4";
              sources = {
                "aarch64-linux" = {
                  filename = "mlir_wheel-${ver}-py3-none-linux_aarch64.whl";
                  hash = "sha256-bUv2LcU+2xfHzNReftK6aAp1sd7yDRwCsCXWa8vnbL8=";
                };
                "x86_64-linux" = {
                  filename = "mlir_wheel-${ver}-py3-none-linux_x86_64.whl";
                  hash = "sha256-hs28VCaxTiw3fp0EqmuPzMNQwvNkKiq0aNvVCDcGddU=";
                };
                "aarch64-darwin" = {
                  filename = "mlir_wheel-${ver}-py3-none-macosx_12_0_arm64.whl";
                  hash = "sha256-C2XmD9+bNatYd/wrY/9JIjx9mMv/FMpRJMsUCIw5V1M=";
                };
              };
              src =
                sources.${pkgs.stdenv.hostPlatform.system}
                  or (throw "mlir-wheel: no wheel for ${pkgs.stdenv.hostPlatform.system}");
            in
            pkgs.stdenv.mkDerivation {
              pname = "mlir-wheel";
              version = ver;
              format = "wheel";

              src = pkgs.fetchurl {
                url = "${base}/${src.filename}";
                inherit (src) hash;
                name = src.filename;
              };

              # The pyproject-wheel-dist-hook sets `buildPhase` (it links the
              # wheel into ./dist for the install hook) and also sets
              # `dontUnpack=1`, so we must NOT set `dontBuild` / `dontUnpack`
              # ourselves — doing so would skip the dist-creation step and
              # break the install hook (`pushd: dist: No such file or directory`).
              nativeBuildInputs = [
                final.pyprojectWheelHook
              ]
              ++ lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;

              buildInputs = lib.optionals pkgs.stdenv.isLinux (
                with pkgs;
                [
                  stdenv.cc.cc.lib
                  zlib
                ]
              );

              dontStrip = true;

              passthru = {
                dependencies = { };
                optional-dependencies = { };
                dependency-groups = { };
                format = "wheel";
              };
            };
        };

        pythonSet = (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
          lib.composeManyExtensions [
            pyproject-build-systems.overlays.default
            pyOverlay
            mlirWheelOverlay
            (final: prev: {
              connection-pool = prev.connection-pool.overrideAttrs (old: {
                nativeBuildInputs =
                  (old.nativeBuildInputs or [ ])
                  ++ final.resolveBuildSystem {
                    setuptools = [ ];
                    wheel = [ ];
                  };
              });
            })
          ]
        );

        # Build-time virtualenv: only the deps needed to compile against MLIR.
        pythonBuildEnv = pythonSet.mkVirtualEnv "tamagoyaki-build-env" workspace.deps.default;

        # ---------- Rival (Rust) ----------
        rustToolchain = pkgs.rust-bin.stable."1.91.0".default;

        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };

        rivalSrc = pkgs.fetchFromGitHub {
          owner = "herbie-fp";
          repo = "rival3";
          rev = "8bc5eca5079497a41d37e20a66c833080c92c0ed"; # pin a commit
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

          # Use the lockfile shipped inside rival3-ffi/. We also need
          # outputHashes only if any deps come from git; rival3-ffi's
          # lock is registry-only, so a plain cargoHash suffices.
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
            lit # llvm-lit, required by add_lit_testsuite in herbie_mlir/test
            pythonBuildEnv # gives configure-time access to the wheel
          ];

          # GMP/MPFR are required to link against librival3_ffi.a (which
          # was built with gmp-mpfr-sys/use-system-libs). The herbie_mlir
          # CMakeLists also prefers these system copies over building from
          # source.
          buildInputs = with pkgs; [
            gmp
            mpfr
            libmpc
          ];

          # Compute MLIR_DIR from the installed wheel and feed it to CMake.
          # The exact subpath inside the wheel is wheel-specific; the snippet
          # below covers the common LLVM-published layout. Verify with:
          #   nix shell .#pythonEnv -c python -c 'import mlir, os; print(os.path.dirname(mlir.__file__))'
          preConfigure = ''
            MLIR_PKG_DIR="$(${pythonBuildEnv}/bin/python -c 'import mlir_wheel, os; print(os.path.dirname(mlir_wheel.__file__))')"
            for cand in \
              "$MLIR_PKG_DIR/lib/cmake/mlir" \
              "$MLIR_PKG_DIR/_mlir_libs/cmake/mlir" \
              "$MLIR_PKG_DIR/cmake/mlir" \
              "$MLIR_PKG_DIR/share/cmake/mlir"; do
              if [ -f "$cand/MLIRConfig.cmake" ]; then
                export MLIR_DIR="$cand"
                break
              fi
            done
            if [ -z "''${MLIR_DIR:-}" ]; then
              echo "Could not locate MLIRConfig.cmake under $MLIR_PKG_DIR" >&2
              find "$MLIR_PKG_DIR" -name 'MLIRConfig.cmake' >&2 || true
              exit 1
            fi
            echo "Using MLIR_DIR=$MLIR_DIR"

            # Skip herbie_mlir/rival's FetchContent + cargo build by
            # pointing at the prebuilt static library + header from the
            # rival-ffi derivation.
            cmakeFlagsArray+=(
              "-DRIVAL_PREBUILT_LIB=${rival-ffi}/lib/librival3_ffi.a"
              "-DRIVAL_PREBUILT_INCLUDE=${rival-ffi}/include"
            )

            # The mlir-wheel doesn't ship llvm-lit; point CMake at the
            # nixpkgs lit binary so add_lit_testsuite is satisfied.
            cmakeFlagsArray+=( "-DLLVM_EXTERNAL_LIT=${pkgs.lit}/bin/lit" )
          '';

          # MLIR_DIR is read from the environment by CMake's find_package.
          # Add other static flags here:
          # cmakeFlags = [ "-DTAMAGOYAKI_USE_FOO=ON" ];

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
          tamagoyaki = tamagoyaki;
          rival-ffi = rival-ffi;
          pythonEnv = pythonBuildEnv;
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
