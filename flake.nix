{
  description = "Tamagoyaki - MLIR-based equality saturation framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

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

          # rival3-ffi needs `let` chains in `if` (stable since 1.88).
          rustToolchain = pkgs.rust-bin.stable."1.91.0".minimal;
          rustPlatform = pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          };

          # gdb is unsupported on Darwin in nixpkgs.
          debuggers =
            if isDarwin then
              [ pkgs.lldb ]
            else
              [
                pkgs.gdb
                pkgs.lldb
              ];

          # Prebuilt rival3-ffi static C-API library, so `nix build` is offline.
          rival-ffi = rustPlatform.buildRustPackage {
            pname = "rival3-ffi";
            version = "unstable-2026-04-28";
            src = rival3-src;

            cargoRoot = "rival3-ffi";
            buildAndTestSubdir = "rival3-ffi";
            cargoHash = "sha256-0KD5zCJotpWKooKLvLZF3sVkPJBVec5lQ4L8CNQzrJo=";
            doCheck = false;

            # Use system GMP/MPFR instead of vendoring them.
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

          # Python interpreter with the Sphinx toolchain the docs build needs.
          # Mirrors docs/requirements.txt so CI builds docs entirely from Nix.
          docsPython = pkgs.python3.withPackages (
            ps: with ps; [
              sphinx
              furo
              myst-parser
              breathe
              sphinx-copybutton
              sphinx-design
              sphinxcontrib-mermaid
              linkify-it-py
            ]
          );

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
                  # LLVM defines _LIBCPP_HARDENING_MODE_EXTENSIVE via its
                  # exported CMake flags when assertions are on (debug). Drop
                  # nix's default libcxxhardeningfast so the two don't both
                  # define _LIBCPP_HARDENING_MODE (-Wmacro-redefined).
                  "libcxxhardeningfast"
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
                    # Install FileCheck/count/not into $out/bin for our lit
                    # suites. Defaults to OFF, so it must be set explicitly.
                    "-DLLVM_INSTALL_UTILS=ON"
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
                  ];

                  meta.platforms = lib.platforms.unix;
                }
              );

              # `tamagoyaki-configure [build-dir] [extra cmake args...]`, using
              # the env the shells below export (CMAKE_PREFIX_PATH, etc.).
              tamagoyaki-configure = pkgs.writeShellScriptBin "tamagoyaki-configure" ''
                set -euo pipefail
                builddir="''${1:-build}"
                shift || true
                exec cmake -G Ninja -B "$builddir" -S . \
                  -DCMAKE_BUILD_TYPE="''${CMAKE_BUILD_TYPE:-${buildType}}" \
                  -DLLVM_EXTERNAL_LIT="''${LLVM_EXTERNAL_LIT}" \
                  -DRIVAL_PREBUILT_LIB="''${RIVAL_PREBUILT_LIB}" \
                  -DRIVAL_PREBUILT_INCLUDE="''${RIVAL_PREBUILT_INCLUDE}" \
                  "$@"
              '';

              # inputsFrom = [ tamagoyaki ] supplies the build tooling and
              # C/C++ deps. The dev shell (ci = false) adds Rust (rival's
              # FetchContent fallback), full racket (Herbie via raco), uv, and
              # debuggers; the CI shell is the minimum to run `check-all`.
              # `docs = true` adds Doxygen + the Sphinx toolchain so the docs
              # build (tablegen -> doxygen -> breathe -> sphinx) runs from Nix.
              mkTamaShell =
                {
                  ci,
                  docs ? false,
                }:
                (pkgs.mkShell.override { inherit stdenv; }) {
                  name = "tamagoyaki${suffix}${lib.optionalString ci "-ci"}${lib.optionalString docs "-docs"}";

                  inputsFrom = [ tamagoyaki ];

                  # mkShell does not propagate hardeningDisable from inputsFrom,
                  # so re-apply the variant's hardening overrides here. Without
                  # this, in-shell incremental builds (`ninja -C build`) get
                  # nix's default flags even though `nix build .#tamagoyaki-*`
                  # would not. In debug, dropping libcxxhardeningfast lets the
                  # _LIBCPP_HARDENING_MODE_EXTENSIVE define that LLVM exports
                  # (when assertions are on) apply without -Wmacro-redefined.
                  inherit (variantAttrs) hardeningDisable;

                  packages = [
                    tamagoyaki-configure
                  ]
                  ++ lib.optionals docs [
                    pkgs.doxygen
                    docsPython
                  ]
                  ++ lib.optionals (!ci) (
                    [ rustToolchain ]
                    ++ (with pkgs; [
                      racket
                      uv
                    ])
                    ++ debuggers
                  );

                  # CMake locates MLIR/LLVM/CIRCT + gmp/mpfr/libmpc here.
                  CMAKE_PREFIX_PATH = lib.concatStringsSep ":" [
                    "${llvm-mlir}"
                    "${circt}"
                    "${pkgs.gmp.dev}"
                    "${pkgs.mpfr.dev}"
                    "${pkgs.libmpc}"
                  ];
                  CMAKE_BUILD_TYPE = buildType;
                  LLVM_EXTERNAL_LIT = "${pkgs.lit}/bin/lit";

                  # Use the prebuilt rival-ffi instead of fetch + cargo build.
                  RIVAL_PREBUILT_LIB = "${rival-ffi}/lib/librival3_ffi.a";
                  RIVAL_PREBUILT_INCLUDE = "${rival-ffi}/include";

                  shellHook = ''
                    # Keep the host PYTHONPATH out of lit's python.
                    unset PYTHONPATH

                    # gmp/mpfr/libmpc are dlopen'd at runtime, so they need to
                    # be on the loader path, not just discoverable at link time.
                    ${
                      if isDarwin then
                        ''export DYLD_LIBRARY_PATH="${
                          lib.makeLibraryPath [
                            pkgs.gmp
                            pkgs.mpfr
                            pkgs.libmpc
                          ]
                        }''${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"''
                      else
                        ''export LD_LIBRARY_PATH="${
                          lib.makeLibraryPath [
                            pkgs.gmp
                            pkgs.mpfr
                            pkgs.libmpc
                          ]
                        }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"''
                    }

                    echo "tamagoyaki ${variant}${lib.optionalString ci " (ci)"} shell ready"
                    echo "  configure: tamagoyaki-configure build"
                    echo "  build:     ninja -C build check-all"
                  '';
                };

              shell = mkTamaShell { ci = false; };
              ciShell = mkTamaShell { ci = true; };
              docsShell = mkTamaShell {
                ci = true;
                docs = true;
              };
            in
            {
              inherit
                llvm-mlir
                circt
                tamagoyaki
                tamagoyaki-configure
                shell
                ciShell
                docsShell
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
            ci = release.ciShell;
            docs = release.docsShell;
          };
        };

      everything = forAllSystems perSystem;
    in
    {
      packages = builtins.mapAttrs (_: v: v.packages) everything;
      devShells = builtins.mapAttrs (_: v: v.devShells) everything;
    };
}
