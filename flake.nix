{
  description = "Nix flake for building Tamagoyaki and related tools (herbie-mlir, rover-mlir, cranelift-mlir)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Provides prebuilt LLVM + MLIR (matching the CIRCT pin).
    circt-nix = {
      url = "github:dtzSiFive/circt-nix";
      inputs.circt-src.url = "github:llvm/circt/firtool-1.146.0";
      inputs.llvm-submodule-src = {
        type = "github";
        owner = "llvm";
        repo = "llvm-project";
        rev = "90c90a41bed5ba2e4c7b724ecfd533f6f3f7d204";
        flake = false;
      };
    };
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

        # ---------- Slimmed LLVM/MLIR from circt-nix ----------
        extraLlvmCmakeFlags = [
          # LLVM_TARGETS_TO_BUILD=host is already on by default
          # (hostOnly = true in circt-nix/llvm.nix), no need to repeat.
          "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="

          # Strip the fat
          "-DLLVM_ENABLE_BACKTRACES=OFF"
          "-DLLVM_INCLUDE_BENCHMARKS=OFF"
          "-DLLVM_INCLUDE_EXAMPLES=OFF"
          "-DLLVM_INCLUDE_TESTS=OFF"
          "-DLLVM_INCLUDE_DOCS=OFF"
          "-DLLVM_BUILD_DOCS=OFF"
          "-DLLVM_ENABLE_OCAMLDOC=OFF"
          "-DLLVM_ENABLE_BINDINGS=OFF"
          "-DLLVM_ENABLE_TERMINFO=OFF"
          "-DLLVM_ENABLE_LIBXML2=OFF"
          "-DLLVM_ENABLE_ZSTD=OFF"
          "-DLLVM_ENABLE_LIBEDIT=OFF"
          # NOTE: LLVM_INSTALL_UTILS is left at its default (ON) so the lit
          # helpers (FileCheck, count, not) end up in $out/bin. Our test
          # suites in cranelift-mlir/, herbie_mlir/ and test/ invoke them
          # via lit's config.llvm_tools_dir, which resolves to
          # ${LLVM_DIR}/../../bin. With INSTALL_UTILS=OFF those binaries
          # are built but never copied to the install prefix, so lit
          # aborts with "Did not find FileCheck".
        ];

        libllvm = (circt-nix.packages.${system}.libllvm.override {
          enableAssertions = false;   # → -DLLVM_ENABLE_ASSERTIONS=OFF
          # hostOnly defaults to true; explicit for clarity.
          hostOnly = true;
          # Build & link against a single libLLVM.so. This collapses
          # every LLVM/MLIR tool (mlir-opt, llc, etc.) from hundreds of
          # MB of statically-linked binary down to a few MB that just
          # dlopen libLLVM.so — the dominant slimming for the cached
          # closure. Sets LLVM_BUILD_LLVM_DYLIB=ON + LLVM_LINK_LLVM_DYLIB=ON.
          enableSharedLibraries = true;
        }).overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or []) ++ extraLlvmCmakeFlags;
        });

        mlir = (circt-nix.packages.${system}.mlir.override {
          enableAssertions = false;
          hostOnly = true;
          # Same reasoning as libllvm above; applied to the MLIR tools.
          enableSharedLibraries = true;
        }).overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or []) ++ [
            "-DLLVM_INCLUDE_TESTS=OFF"
            "-DMLIR_INCLUDE_TESTS=OFF"
            "-DMLIR_INCLUDE_INTEGRATION_TESTS=OFF"
          ];
        });

        circt = (circt-nix.packages.${system}.circt.override {
          # Rebuild circt against our slimmed libllvm/mlir so the
          # closure doesn't end up with two copies of LLVM/MLIR.
          inherit libllvm mlir;
          enableSlang   = false;
          enableLLHD    = false;
          enableOrTools = false;
          enableDocs    = false;
          enableAssertions = false;
          withVerilator = false;
        }).overrideAttrs (old: {
          patches =
            (lib.filter
              (p: !lib.hasInfix "circt-mlir-tblgen-path" (toString p))
              (old.patches or []))
            ++ [ ./nix/patches/circt-mlir-tblgen-path.patch ];
          cmakeFlags = (old.cmakeFlags or []) ++ [
            "-DCIRCT_INCLUDE_TESTS=OFF"
          ];
          doCheck = false;
        });

        # ---------- Rival (Rust) ----------
        rustToolchain = pkgs.rust-bin.stable."1.91.0".minimal;

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
            lit
          ];

          buildInputs = [
            mlir.dev
            libllvm.dev
            circt.dev
            circt.lib
          ] ++ (with pkgs; [ gmp mpfr libmpc ]);

          cmakeFlags = [
            "-DMLIR_DIR=${mlir.dev}/lib/cmake/mlir"
            "-DLLVM_DIR=${libllvm.dev}/lib/cmake/llvm"
            "-DCIRCT_DIR=${circt.dev}/lib/cmake/circt"
            "-DLLVM_EXTERNAL_LIT=${pkgs.lit}/bin/lit"
            "-DRIVAL_PREBUILT_LIB=${rival-ffi}/lib/librival3_ffi.a"
            "-DRIVAL_PREBUILT_INCLUDE=${rival-ffi}/include"
            "-DBUILD_SHARED_LIBS=ON"
          ];

          meta = with lib; {
            description = "Tamagoyaki MLIR equality saturation tool";
            platforms = platforms.unix;
          };
        };

        # ---------- Shared bits for the configure wrapper ----------
        sharedLibExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;

        cmakePrefixPath = lib.concatStringsSep ";" [
          "${mlir.dev}"
          "${libllvm.dev}"
          "${circt.dev}"
          "${pkgs.gmp.dev}"
          "${pkgs.mpfr.dev}"
        ];

        # circt-nix's prebuilt LLVM was compiled with macOS deployment
        # target 14.0. Linking it with the nixpkgs default (11.3 on
        # 25.05) produces a flood of "object file ... was built for
        # newer macOS version (14.0) than being linked (11.3)" warnings,
        # so we pin our own target to match.
        darwinDeploymentTarget = "14.0";

        deploymentTargetFlag =
          lib.optionalString pkgs.stdenv.isDarwin
            "-DCMAKE_OSX_DEPLOYMENT_TARGET=${darwinDeploymentTarget}";

        # ---------- Shell-agnostic configure wrapper ----------
        # A real script on PATH (works from bash / zsh / fish / nushell
        # / etc.). All nix store paths are baked in at build time, so
        # the script does not depend on env vars set by shellHook.
        tamagoyaki-configure = pkgs.writeShellApplication {
          name = "tamagoyaki-configure";
          runtimeInputs = with pkgs; [
            cmake
            ninja
            lit
            coreutils
          ];
          # shellcheck flags off our intentional quoted-but-empty
          # deploymentTargetFlag on linux; suppress that lint.
          checkPhase = "";
          text = ''
            set -euo pipefail

            builddir="''${1:-build}"
            if [ $# -gt 0 ]; then shift; fi

            if [ ! -f CMakeLists.txt ]; then
              echo "tamagoyaki-configure: must be run from the project root" >&2
              echo "  (no CMakeLists.txt in $(pwd))" >&2
              exit 1
            fi

            echo "==> Wiping $builddir/ to discard any stale CMake cache"
            rm -rf "$builddir"

            echo "==> Configuring $builddir/"
            cmake -G Ninja \
              -B "$builddir" -S . \
              -DCMAKE_BUILD_TYPE=Release \
              ${deploymentTargetFlag} \
              -DCMAKE_PREFIX_PATH="${cmakePrefixPath}" \
              -DMLIR_DIR="${mlir.dev}/lib/cmake/mlir" \
              -DLLVM_DIR="${libllvm.dev}/lib/cmake/llvm" \
              -DCIRCT_DIR="${circt.dev}/lib/cmake/circt" \
              -DLLVM_EXTERNAL_LIT="${pkgs.lit}/bin/lit" \
              -DGMP_LIBRARY="${pkgs.gmp}/lib/libgmp${sharedLibExt}" \
              -DGMP_INCLUDE_DIR="${pkgs.gmp.dev}/include" \
              -DMPFR_LIBRARY="${pkgs.mpfr}/lib/libmpfr${sharedLibExt}" \
              -DMPFR_INCLUDE_DIR="${pkgs.mpfr.dev}/include" \
              -DRIVAL_PREBUILT_LIB="${rival-ffi}/lib/librival3_ffi.a" \
              -DRIVAL_PREBUILT_INCLUDE="${rival-ffi}/include" \
              "$@"

            echo ""
            echo "Configured. Build with:"
            echo "  ninja -C $builddir check-all"
          '';
        };

      in
      {
        packages = {
          default = tamagoyaki;
          inherit tamagoyaki rival-ffi mlir circt tamagoyaki-configure;
        };

        devShells = {
          # ---------- CI shell ----------
          # The minimum needed to configure and run `ninja check-all`
          # against the prebuilt LLVM/MLIR/CIRCT/rival-ffi from the
          # binary cache. No Rust toolchain, no Racket, no Herbie
          # graphics deps — those are only needed for development, not
          # for running the test suite. This is what
          # `.github/workflows/test.yml` uses.
          #
          # cmake/ninja/lit/pkg-config and the LLVM/MLIR/CIRCT/gmp/mpfr
          # closure all come in via `inputsFrom = [ tamagoyaki ]` and
          # so don't need to be listed explicitly.
          ci = pkgs.mkShell {
            name = "tamagoyaki-ci";
            inputsFrom = [ tamagoyaki ];
            packages = [ tamagoyaki-configure ];

            shellHook = ''
              # Lit is python; don't let the system PYTHONPATH leak in.
              unset PYTHONPATH
            '' + lib.optionalString pkgs.stdenv.isDarwin ''
              export MACOSX_DEPLOYMENT_TARGET="${darwinDeploymentTarget}"
            '';
          };

          # ---------- Full developer shell ----------
          # Everything in `ci` plus: Rust toolchain (for iterating on
          # rival-ffi), Racket + graphics libs (for Herbie), uv (for
          # Python eval scripts), and ad-hoc env vars convenient for
          # poking at the build from inside the shell.
          default = pkgs.mkShell {
            name = "tamagoyaki-dev";
            inputsFrom = [ tamagoyaki ];

            # Expose the prebuilt CIRCT/MLIR/LLVM packages so they're
            # readily available for ad-hoc commands inside the shell.
            inherit circt mlir;

            packages = (with pkgs; [
              rustToolchain
              racket-minimal
              flex
              bison
              fontconfig
              cairo
              pango
              libjpeg
              libpng
              zlib
              uv
            ]) ++ [
              tamagoyaki-configure
            ];

            # Exposed for ad-hoc use; the configure wrapper is the
            # supported entry point because CMake does not honour most
            # of these as environment variables (only CMAKE_PREFIX_PATH).
            MLIR_DIR  = "${mlir.dev}/lib/cmake/mlir";
            LLVM_DIR  = "${libllvm.dev}/lib/cmake/llvm";
            CIRCT_DIR = "${circt.dev}/lib/cmake/circt";
            GMP_PREFIX  = "${pkgs.gmp}";
            GMP_DEV     = "${pkgs.gmp.dev}";
            MPFR_PREFIX = "${pkgs.mpfr}";
            MPFR_DEV    = "${pkgs.mpfr.dev}";
            RIVAL_PREBUILT_LIB     = "${rival-ffi}/lib/librival3_ffi.a";
            RIVAL_PREBUILT_INCLUDE = "${rival-ffi}/include";

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
              case "$(uname)" in
                Darwin)
                  export DYLD_FALLBACK_LIBRARY_PATH="$RACKET_FFI_LIB_PATH''${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
                  export MACOSX_DEPLOYMENT_TARGET="${darwinDeploymentTarget}"
                  ;;
                *)
                  export LD_LIBRARY_PATH="$RACKET_FFI_LIB_PATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                  ;;
              esac

              # Don't let the system Python interfere with uv-managed envs.
              unset PYTHONPATH

              echo "tamagoyaki dev shell ready"
              echo "  uv     : $(uv --version)"
              echo "  cargo  : $(cargo --version)"
              echo "  cmake  : $(cmake --version | head -1)"
              echo "  lit    : $(command -v lit)"
              echo "  MLIR   : $MLIR_DIR"
              echo "  LLVM   : $LLVM_DIR"
              echo "  CIRCT  : $CIRCT_DIR  (required by rover-mlir)"
              echo ""
              echo "Configure & build with:"
              echo "  tamagoyaki-configure"
              echo "  ninja -C build check-all      # build & run all test suites"
            '';
          };
        };
      }
    );
}
