{
  description = "Tamagoyaki - MLIR-based equality saturation framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llvm-project-src = {
      url = "github:llvm/llvm-project/a47d3636f953870d96fb6cc68817365fdad2f9fe";
      flake = false;
    };
    circt-src = {
      url = "github:llvm/circt/96997a18c388f8c7a05344f3f39805bd7856236a";
      flake = false;
    };
    rival3-src = {
      url = "github:herbie-fp/rival3/8bc5eca5079497a41d37e20a66c833080c92c0ed";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      llvm-project-src,
      circt-src,
      rival3-src,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      perSystem =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };
          lib = pkgs.lib;
          stdenv = pkgs.llvmPackages_latest.stdenv;
          isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

          # rival3-ffi uses `let` chains in `if`, stabilised in 1.88, so
          # we pin a recent stable rather than rely on whatever rustc the
          # current nixpkgs channel ships.
          rustToolchain = pkgs.rust-bin.stable."1.91.0".minimal;
          rustPlatform = pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          };

          # gdb is broken / unsupported on Darwin in nixpkgs.
          debuggers =
            if isDarwin then
              [ pkgs.lldb ]
            else
              [
                pkgs.gdb
                pkgs.lldb
              ];

          # ---------- Rival (Rust) ----------
          # rival3-ffi static C-API library. We pre-build it via Nix so
          # `nix build` works offline. The dev shell ships cargo so the
          # CMake build can fall back to FetchContent + cargo if needed.
          rival-ffi = rustPlatform.buildRustPackage {
            pname = "rival3-ffi";
            version = "unstable-2026-04-28";
            src = rival3-src;

            cargoRoot = "rival3-ffi";
            buildAndTestSubdir = "rival3-ffi";
            cargoHash = "sha256-0KD5zCJotpWKooKLvLZF3sVkPJBVec5lQ4L8CNQzrJo=";
            doCheck = false;

            # Use system GMP/MPFR instead of letting gmp-mpfr-sys vendor them.
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
              cp target/*/release/librival3_ffi.a $out/lib/ 2>/dev/null \
                || cp target/release/librival3_ffi.a $out/lib/
              cp rival3-ffi/include/rival.h $out/include/
              runHook postInstall
            '';
          };

          # ---------- LLVM/MLIR + CIRCT, with debug & release variants ----------
          mkVariant =
            { variant }:
            let
              isDebug = variant == "debug";
              suffix = lib.optionalString isDebug "-debug";
              buildType = if isDebug then "RelWithDebInfo" else "Release";

              commonCmakeFlags = [
                "-DLLVM_ENABLE_ASSERTIONS=${if isDebug then "ON" else "OFF"}"
                "-DLLVM_ENABLE_RTTI=ON"
                "-DLLVM_ENABLE_TERMINFO=OFF"
                "-DLLVM_ENABLE_ZSTD=OFF"
                "-DLLVM_TARGETS_TO_BUILD=Native"
                "-DLLVM_LINK_LLVM_DYLIB=ON"
                "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON"
              ]
              ++ lib.optionals isDebug [ "-DLLVM_PARALLEL_LINK_JOBS=1" ];

              variantAttrs = {
                cmakeBuildType = buildType;
                dontStrip = isDebug;
                hardeningDisable = [
                  "trivialautovarinit"
                  "shadowstack"
                ]
                ++ lib.optionals isDebug [
                  "fortify"
                  "fortify3"
                ];
              };

              llvm-mlir = stdenv.mkDerivation (
                variantAttrs
                // {
                  pname = "llvm-mlir${suffix}";
                  version = "custom";
                  src = llvm-project-src;
                  sourceRoot = "source/llvm";
                  nativeBuildInputs = with pkgs; [
                    cmake
                    ninja
                    python3
                  ];
                  buildInputs = with pkgs; [
                    zlib
                    libffi
                  ];
                  cmakeFlags = commonCmakeFlags ++ [
                    "-DLLVM_ENABLE_PROJECTS=mlir"
                    "-DLLVM_BUILD_LLVM_DYLIB=ON"
                    # Strip everything we don't need.
                    "-DLLVM_INCLUDE_TESTS=OFF"
                    "-DLLVM_BUILD_TESTS=OFF"
                    "-DLLVM_INCLUDE_EXAMPLES=OFF"
                    "-DLLVM_BUILD_EXAMPLES=OFF"
                    "-DLLVM_INCLUDE_BENCHMARKS=OFF"
                    "-DLLVM_INCLUDE_DOCS=OFF"
                    "-DLLVM_BUILD_DOCS=OFF"
                    "-DMLIR_INCLUDE_TESTS=OFF"
                    "-DMLIR_INCLUDE_INTEGRATION_TESTS=OFF"
                    "-DMLIR_BUILD_MLIR_C_DYLIB=OFF"
                    # Keep LLVM_INSTALL_UTILS at default ON so FileCheck,
                    # count and not end up in $out/bin for our lit suites.
                  ];
                  meta.platforms = lib.platforms.unix;
                  preConfigure = lib.optionalString isDebug ''
                    export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:-} -ffile-prefix-map=$NIX_BUILD_TOP/source=${llvm-project-src}"
                  '';
                }
              );

              circt = stdenv.mkDerivation (
                variantAttrs
                // {
                  pname = "circt${suffix}";
                  version = "custom";
                  src = circt-src;
                  nativeBuildInputs =
                    with pkgs;
                    [
                      cmake
                      ninja
                      python3
                    ]
                    ++ lib.optionals stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
                  propagatedBuildInputs = [ llvm-mlir ];
                  buildInputs = with pkgs; [
                    zlib
                    libffi
                  ];
                  cmakeFlags = commonCmakeFlags ++ [
                    "-DMLIR_DIR=${llvm-mlir}/lib/cmake/mlir"
                    "-DLLVM_DIR=${llvm-mlir}/lib/cmake/llvm"
                    "-DCIRCT_INCLUDE_TESTS=OFF"
                    "-DCIRCT_INCLUDE_INTEGRATION_TESTS=OFF"
                    "-DCIRCT_BINDINGS_PYTHON_ENABLED=OFF"
                    "-DCIRCT_SLANG_FRONTEND_ENABLED=OFF"
                  ];
                  meta.platforms = lib.platforms.unix;
                  preConfigure = lib.optionalString isDebug ''
                    export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:-} -ffile-prefix-map=$NIX_BUILD_TOP/source=${circt-src}"
                  '';
                }
              );

              # ---------- Tamagoyaki (the project itself) ----------
              tamagoyaki = stdenv.mkDerivation (
                variantAttrs
                // {
                  pname = "tamagoyaki${suffix}";
                  version = "0.1.0";
                  src = lib.cleanSource ./.;

                  nativeBuildInputs = with pkgs; [
                    cmake
                    ninja
                    python3
                    lit
                    git
                    m4
                    pkg-config
                  ];
                  buildInputs = [
                    llvm-mlir
                    circt
                    rival-ffi
                  ]
                  ++ (with pkgs; [
                    gmp
                    mpfr
                    libmpc
                    zlib
                    libffi
                  ]);

                  cmakeFlags = [
                    "-DMLIR_DIR=${llvm-mlir}/lib/cmake/mlir"
                    "-DLLVM_DIR=${llvm-mlir}/lib/cmake/llvm"
                    "-DCIRCT_DIR=${circt}/lib/cmake/circt"
                    "-DLLVM_EXTERNAL_LIT=${pkgs.lit}/bin/lit"
                    "-DRIVAL_PREBUILT_LIB=${rival-ffi}/lib/librival3_ffi.a"
                    "-DRIVAL_PREBUILT_INCLUDE=${rival-ffi}/include"
                    "-DBUILD_SHARED_LIBS=ON"
                  ];

                  meta.platforms = lib.platforms.unix;
                }
              );

              # ---------- Dev shell ----------
              # Everything needed to configure and build tamagoyaki by hand.
              # Notably: rustToolchain (so CMake's FetchContent path can build
              # rival against the network), racket (so the user can install
              # Herbie later via `raco pkg install ...` -- we use the full
              # racket so Herbie's draw-lib/plot-lib deps find Cairo, Pango,
              # fontconfig etc. via FFI), and uv (for the Python eval scripts
              # in herbie_mlir/).
              shell = (pkgs.mkShell.override { inherit stdenv; }) {
                name = "tamagoyaki${suffix}";

                inputsFrom = [ tamagoyaki ];

                packages = [
                  rustToolchain
                ]
                ++ (with pkgs; [
                  racket
                  uv
                ])
                ++ debuggers;

                # CMake picks up MLIR/LLVM/CIRCT (and gmp/mpfr/libmpc, since
                # they are in buildInputs) via CMAKE_PREFIX_PATH.
                CMAKE_PREFIX_PATH = lib.concatStringsSep ":" [
                  "${llvm-mlir}"
                  "${circt}"
                  "${pkgs.gmp.dev}"
                  "${pkgs.mpfr.dev}"
                  "${pkgs.libmpc}"
                ];
                CMAKE_BUILD_TYPE = buildType;
                LLVM_EXTERNAL_LIT = "${pkgs.lit}/bin/lit";

                # Use the prebuilt rival-ffi (linked against the bundled
                # gmp/mpfr) instead of letting CMake fetch + cargo build it.
                RIVAL_PREBUILT_LIB = "${rival-ffi}/lib/librival3_ffi.a";
                RIVAL_PREBUILT_INCLUDE = "${rival-ffi}/include";

                shellHook = ''
                  # Don't let the host PYTHONPATH leak into lit's python.
                  unset PYTHONPATH

                  echo "tamagoyaki ${variant} shell ready"
                  echo "  configure: cmake -G Ninja -B build -S . \\"
                  echo "               -DLLVM_EXTERNAL_LIT=$LLVM_EXTERNAL_LIT \\"
                  echo "               -DRIVAL_PREBUILT_LIB=$RIVAL_PREBUILT_LIB \\"
                  echo "               -DRIVAL_PREBUILT_INCLUDE=$RIVAL_PREBUILT_INCLUDE"
                  echo "  build:     ninja -C build check-all"
                '';
              };
            in
            {
              inherit
                llvm-mlir
                circt
                tamagoyaki
                shell
                ;
            };

          release = mkVariant { variant = "release"; };
          debug = mkVariant { variant = "debug"; };
        in
        {
          packages = {
            default = release.tamagoyaki;
            tamagoyaki = release.tamagoyaki;
            tamagoyaki-debug = debug.tamagoyaki;
            llvm-mlir = release.llvm-mlir;
            llvm-mlir-debug = debug.llvm-mlir;
            circt = release.circt;
            circt-debug = debug.circt;
            inherit rival-ffi;
          };
          devShells = {
            default = release.shell;
            debug = debug.shell;
          };
        };

      everything = forAllSystems perSystem;
    in
    {
      packages = builtins.mapAttrs (_: v: v.packages) everything;
      devShells = builtins.mapAttrs (_: v: v.devShells) everything;
    };
}
