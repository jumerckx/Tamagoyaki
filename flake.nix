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

        # ---------- LLVM / MLIR / CIRCT (Release, from circt-nix cachix) ----------
        circtOverrides = {
          enableSlang = false;
          enableLLHD = false;
          enableOrTools = false;
          enableDocs = false;
          withVerilator = false;
        };

        mlir = circt-nix.packages.${system}.mlir;
        libllvm = circt-nix.packages.${system}.libllvm;
        circt = circt-nix.packages.${system}.circt.override circtOverrides;

        # ---------- LLVM / MLIR / CIRCT (Debug, rebuilt locally) ----------
        # The dtz-circt cachix only carries Release artifacts, so the Debug
        # variants below trigger a full local rebuild of LLVM and CIRCT —
        # expect multi-hour compilation and several GB of installed libs
        # the first time you enter `nix develop .#debug`.
        mkDebug = drv: drv.overrideAttrs (old: {
          cmakeBuildType = "Debug";
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [
            "-DLLVM_ENABLE_ASSERTIONS=ON"
          ];
          dontStrip = true;
          separateDebugInfo = false;
        });

        libllvm-debug = mkDebug libllvm;

        mlir-debug = (mkDebug mlir).overrideAttrs (old: {
          # Ensure we use the debug version of LLVM
          buildInputs = [ libllvm-debug.dev ]
            ++ (lib.filter (x: x != libllvm && x != libllvm.dev && x != libllvm.lib && x != libllvm.out) (old.buildInputs or [ ]));
        });

        circt-debug = (mkDebug (circt-nix.packages.${system}.circt.override circtOverrides)).overrideAttrs (old: {
          # Ensure we use debug versions of MLIR and LLVM
          buildInputs = [ mlir-debug.dev libllvm-debug.dev ]
            ++ (lib.filter (x: x != mlir && x != mlir.dev && x != mlir.out && x != libllvm && x != libllvm.dev && x != libllvm.lib && x != libllvm.out) (old.buildInputs or [ ]));
        });

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

        rival-ffi = rustPlatform.buildRustPackage {
          pname = "rival3-ffi";
          version = "unstable-2026-04-28";

          src = rivalSrc;

          cargoRoot = "rival3-ffi";
          buildAndTestSubdir = "rival3-ffi";

          cargoHash = "sha256-0KD5zCJotpWKooKLvLZF3sVkPJBVec5lQ4L8CNQzrJo=";

          doCheck = false;

          cargoBuildFlags = [
            "--features"
            "gmp-mpfr-sys/use-system-libs"
          ];

          nativeBuildInputs = with pkgs; [
            m4
            pkg-config
            rustPlatform.bindgenHook
          ];

          buildInputs = with pkgs; [
            gmp
            mpfr
            libmpc
          ];

          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib $out/include
            cp target/*/release/librival3_ffi.a $out/lib/ 2>/dev/null || \
              cp target/release/librival3_ffi.a $out/lib/
            cp rival3-ffi/include/rival.h $out/include/
            runHook postInstall
          '';
        };

        # ---------- Main C++/MLIR build (parameterised) ----------
        makeTamagoyaki =
          { mlirPkg, libllvmPkg, circtPkg, buildType }:
          pkgs.stdenv.mkDerivation {
            pname = "tamagoyaki" + lib.optionalString (buildType != "Release") "-${lib.toLower buildType}";
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
              mlirPkg.dev
              libllvmPkg.dev
              circtPkg.dev
              circtPkg.lib
            ]
            ++ (with pkgs; [
              gmp
              mpfr
              libmpc
            ]);

            cmakeBuildType = buildType;
            dontStrip = buildType != "Release";

            cmakeFlags = [
              "-DMLIR_DIR=${mlirPkg.dev}/lib/cmake/mlir"
              "-DLLVM_DIR=${libllvmPkg.dev}/lib/cmake/llvm"
              "-DCIRCT_DIR=${circtPkg.dev}/lib/cmake/circt"
              "-DLLVM_EXTERNAL_LIT=${pkgs.lit}/bin/lit"
              "-DRIVAL_PREBUILT_LIB=${rival-ffi}/lib/librival3_ffi.a"
              "-DRIVAL_PREBUILT_INCLUDE=${rival-ffi}/include"
            ]
            ++ lib.optional (buildType != "Release") "-DLLVM_ENABLE_ASSERTIONS=ON";

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
              description = "Tamagoyaki MLIR equality saturation tool"
                + lib.optionalString (buildType != "Release") " (${buildType})";
              platforms = platforms.unix;
            };
          };

        tamagoyaki = makeTamagoyaki {
          mlirPkg = mlir;
          libllvmPkg = libllvm;
          circtPkg = circt;
          buildType = "Release";
        };

        tamagoyaki-debug = makeTamagoyaki {
          mlirPkg = mlir-debug;
          libllvmPkg = libllvm-debug;
          circtPkg = circt-debug;
          buildType = "Debug";
        };

        # ---------- Shell-agnostic configure wrapper (parameterised) ----------
        sharedLibExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
        cmakeIgnorePaths = lib.concatStringsSep ";" [
          "/opt/homebrew"
          "/opt/homebrew/bin"
          "/opt/homebrew/lib"
          "/opt/homebrew/include"
          "/usr/local"
          "/usr/local/bin"
          "/usr/local/lib"
          "/usr/local/include"
        ];

        darwinDeploymentTarget = "14.0";
        deploymentTargetFlag =
          lib.optionalString pkgs.stdenv.isDarwin
            "-DCMAKE_OSX_DEPLOYMENT_TARGET=${darwinDeploymentTarget}";

        makeConfigure =
          { name, mlirPkg, libllvmPkg, circtPkg, buildType, defaultBuilddir }:
          let
            cmakePrefixPath = lib.concatStringsSep ";" [
              "${mlirPkg.dev}"
              "${libllvmPkg.dev}"
              "${circtPkg.dev}"
              "${pkgs.gmp.dev}"
              "${pkgs.mpfr.dev}"
              "${pkgs.libmpc}"
            ];
            extraFlags = lib.optionalString (buildType != "Release")
              "-DLLVM_ENABLE_ASSERTIONS=ON";
          in
          pkgs.writeShellApplication {
            inherit name;
            runtimeInputs = with pkgs; [
              cmake
              ninja
              lit
              coreutils
            ];
            checkPhase = "";
            text = ''
              set -euo pipefail

              builddir="''${1:-${defaultBuilddir}}"
              if [ $# -gt 0 ]; then shift; fi

              if [ ! -f CMakeLists.txt ]; then
                echo "${name}: must be run from the project root" >&2
                echo "  (no CMakeLists.txt in $(pwd))" >&2
                exit 1
              fi

              echo "==> Wiping $builddir/ to discard any stale CMake cache"
              rm -rf "$builddir"

              echo "==> Configuring $builddir/ (CMAKE_BUILD_TYPE=${buildType})"
              cmake -G Ninja \
                -B "$builddir" -S . \
                -DCMAKE_BUILD_TYPE=${buildType} \
                ${extraFlags} \
                ${deploymentTargetFlag} \
                -DCMAKE_IGNORE_PATH="${cmakeIgnorePaths}" \
                -DCMAKE_IGNORE_PREFIX_PATH="/opt/homebrew;/usr/local" \
                -DCMAKE_PREFIX_PATH="${cmakePrefixPath}" \
                -DMLIR_DIR="${mlirPkg.dev}/lib/cmake/mlir" \
                -DLLVM_DIR="${libllvmPkg.dev}/lib/cmake/llvm" \
                -DCIRCT_DIR="${circtPkg.dev}/lib/cmake/circt" \
                -DLLVM_EXTERNAL_LIT="${pkgs.lit}/bin/lit" \
                -DGMP_LIBRARY="${pkgs.gmp}/lib/libgmp${sharedLibExt}" \
                -DGMP_INCLUDE_DIR="${pkgs.gmp.dev}/include" \
                -DMPFR_LIBRARY="${pkgs.mpfr}/lib/libmpfr${sharedLibExt}" \
                -DMPFR_INCLUDE_DIR="${pkgs.mpfr.dev}/include" \
                -DMPC_LIBRARY="${pkgs.libmpc}/lib/libmpc${sharedLibExt}" \
                -DMPC_INCLUDE_DIR="${pkgs.libmpc}/include" \
                -DRIVAL_PREBUILT_LIB="${rival-ffi}/lib/librival3_ffi.a" \
                -DRIVAL_PREBUILT_INCLUDE="${rival-ffi}/include" \
                "$@"

              echo ""
              echo "Configured. Build with:"
              echo "  ninja -C $builddir check-all"

              # Symlink compile_commands.json to root for editor support
              if [ -f "$builddir/compile_commands.json" ]; then
                echo "==> Symlinking $builddir/compile_commands.json to root"
                ln -sf "$builddir/compile_commands.json" .
              fi
            '';
          };

        tamagoyaki-configure = makeConfigure {
          name = "tamagoyaki-configure";
          mlirPkg = mlir;
          libllvmPkg = libllvm;
          circtPkg = circt;
          buildType = "Release";
          defaultBuilddir = "build";
        };

        tamagoyaki-configure-debug = makeConfigure {
          name = "tamagoyaki-configure-debug";
          mlirPkg = mlir-debug;
          libllvmPkg = libllvm-debug;
          circtPkg = circt-debug;
          buildType = "Debug";
          defaultBuilddir = "build-debug";
        };

        # ---------- Dev shell (parameterised) ----------
        makeShell =
          { name, mlirPkg, libllvmPkg, circtPkg, tamagoyakiPkg, configurePkg, buildType, banner }:
          pkgs.mkShell {
            inherit name;
            inputsFrom = [ tamagoyakiPkg ];

            mlir = mlirPkg;
            libllvm = libllvmPkg;
            circt = circtPkg;

            packages = (with pkgs; [
              rustToolchain
              racket-minimal
              flex
              bison
              gmp
              mpfr
              libmpc
              fontconfig
              cairo
              pango
              libjpeg
              libpng
              zlib
              uv
              lit
              cmake
              ninja
              pkg-config
            ]) ++ [ configurePkg ];

            MLIR_DIR = "${mlirPkg.dev}/lib/cmake/mlir";
            LLVM_DIR = "${libllvmPkg.dev}/lib/cmake/llvm";
            CIRCT_DIR = "${circtPkg.dev}/lib/cmake/circt";
            GMP_PREFIX = "${pkgs.gmp}";
            GMP_DEV    = "${pkgs.gmp.dev}";
            MPFR_PREFIX = "${pkgs.mpfr}";
            MPFR_DEV    = "${pkgs.mpfr.dev}";
            RIVAL_PREBUILT_LIB = "${rival-ffi}/lib/librival3_ffi.a";
            RIVAL_PREBUILT_INCLUDE = "${rival-ffi}/include";
            TAMAGOYAKI_BUILD_TYPE = buildType;

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

              unset PYTHONPATH

              ${banner}
            '';
          };

      in
      {
        packages = {
          default = tamagoyaki;
          inherit
            tamagoyaki
            tamagoyaki-debug
            rival-ffi
            mlir
            libllvm
            circt
            mlir-debug
            libllvm-debug
            circt-debug
            tamagoyaki-configure
            tamagoyaki-configure-debug
            ;
        };

        devShells.default = makeShell {
          name = "tamagoyaki-eval";
          mlirPkg = mlir;
          libllvmPkg = libllvm;
          circtPkg = circt;
          tamagoyakiPkg = tamagoyaki;
          configurePkg = tamagoyaki-configure;
          buildType = "Release";
          banner = ''
            echo "tamagoyaki eval shell ready (Release)"
            echo "  uv     : $(uv --version)"
            echo "  cargo  : $(cargo --version)"
            echo "  cmake  : $(cmake --version | head -1)"
            echo "  lit    : $(command -v lit)"
            echo "  MLIR   : $MLIR_DIR"
            echo "  LLVM   : $LLVM_DIR"
            echo "  CIRCT  : $CIRCT_DIR  (required by rover-mlir)"
            echo ""
            echo "Configure & build with:"
            echo "  tamagoyaki-configure          # works from bash / zsh / fish / nushell"
            echo "  ninja -C build check-all      # build & run all test suites"
          '';
        };

        devShells.debug = makeShell {
          name = "tamagoyaki-eval-debug";
          mlirPkg = mlir-debug;
          libllvmPkg = libllvm-debug;
          circtPkg = circt-debug;
          tamagoyakiPkg = tamagoyaki-debug;
          configurePkg = tamagoyaki-configure-debug;
          buildType = "Debug";
          banner = ''
            echo "tamagoyaki eval shell ready (DEBUG — full LLVM/MLIR/CIRCT debug build)"
            echo ""
            echo "  uv     : $(uv --version)"
            echo "  cargo  : $(cargo --version)"
            echo "  cmake  : $(cmake --version | head -1)"
            echo "  lit    : $(command -v lit)"
            echo "  MLIR   : $MLIR_DIR"
            echo "  LLVM   : $LLVM_DIR"
            echo "  CIRCT  : $CIRCT_DIR"
            echo ""
            echo "Configure & build with:"
            echo "  tamagoyaki-configure-debug              # defaults to build-debug/"
            echo "  ninja -C build-debug check-all"
          '';
        };
      }
    );
}
