{
  description = "Tamagoyaki - MLIR-based equality saturation framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # uv2nix toolchain: build the Python environment straight from
    # pyproject.toml + uv.lock so the flake and uv share one source of truth.
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

    llvm-project-src = {
      url = "github:llvm/llvm-project/040a641988f6ed6f4fab250706ca2b620c1de2d8";
      flake = false;
    };
    # The case studies -- herbie_mlir and rover-mlir, and the evaluations --
    # live in their own repository and bring their own CIRCT, Rust, Rival 3 and
    # Herbie/Racket closure. They consume this flake as an input:
    #   https://github.com/jumerckx/tamagoyaki-case-studies
  };

  outputs =
    {
      self,
      nixpkgs,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      llvm-project-src,
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
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
          stdenv = pkgs.llvmPackages_latest.stdenv;
          isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

          # gdb is unsupported on Darwin in nixpkgs.
          debuggers =
            if isDarwin then
              [ pkgs.lldb ]
            else
              [
                pkgs.gdb
                pkgs.lldb
              ];

          python = pkgs.python313;
          uvWorkspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
          uvOverlay = uvWorkspace.mkPyprojectOverlay {
            # Prefer prebuilt wheels; avoids compiling sdists from PyPI.
            sourcePreference = "wheel";
          };
          # Per-package build-fixups layered on top of the generated overlay.
          # connection-pool (a snakemake transitive dep) is an sdist-only legacy
          # package that builds with setuptools but never declares it, so uv's
          # isolated build can't find the backend. Inject it explicitly.
          pyprojectOverrides = final: prev: {
            connection-pool = prev.connection-pool.overrideAttrs (old: {
              nativeBuildInputs =
                (old.nativeBuildInputs or [ ])
                ++ final.resolveBuildSystem { setuptools = [ ]; };
            });
          };
          pythonSet =
            (pkgs.callPackage pyproject-nix.build.packages {
              inherit python;
            }).overrideScope
              (lib.composeManyExtensions [
                pyproject-build-systems.overlays.default
                uvOverlay
                pyprojectOverrides
              ]);
          pythonEnv = pythonSet.mkVirtualEnv "tamagoyaki-env" uvWorkspace.deps.all;

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
                    "-DLLVM_INSTALL_UTILS=ON"
                  ];
                  meta.platforms = lib.platforms.unix;
                  preConfigure = lib.optionalString isDebug ''
                    export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:-} -ffile-prefix-map=$NIX_BUILD_TOP/source=${llvm-project-src}"
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
                  ]
                  ++ (with pkgs; [
                    gmp
                    mpfr
                    libmpc
                    zlib
                    libffi
                    # HiGHS solver for the equivalence-select-ilp pass. Disable
                    # with -DTAMAGOYAKI_ENABLE_HIGHS=OFF to drop this dependency.
                    highs
                  ]);

                  cmakeFlags = [
                    "-DMLIR_DIR=${llvm-mlir}/lib/cmake/mlir"
                    "-DLLVM_DIR=${llvm-mlir}/lib/cmake/llvm"
                    "-DLLVM_EXTERNAL_LIT=${pkgs.lit}/bin/lit"
                    "-DCMAKE_INSTALL_RPATH=${llvm-mlir}/lib"
                    "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON"
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
                  "$@"
              '';

              # inputsFrom = [ tamagoyaki ] supplies the build tooling and
              # C/C++ deps. The dev shell (ci = false) adds uv and debuggers;
              # the CI shell is the minimum to run `check-all`. `docs = true`
              # adds Doxygen + the Sphinx toolchain so the docs build
              # (tablegen -> doxygen -> breathe -> sphinx) runs from Nix.
              mkTamaShell =
                {
                  ci,
                  docs ? false,
                }:
                (pkgs.mkShell.override { inherit stdenv; }) ({
                  name = "tamagoyaki${suffix}${lib.optionalString ci "-ci"}${lib.optionalString docs "-docs"}";

                  inputsFrom = [ tamagoyaki ];

                  inherit (variantAttrs) hardeningDisable;

                  packages = [
                    tamagoyaki-configure
                  ]
                  ++ lib.optionals docs [
                    pkgs.doxygen
                    pythonEnv
                  ]
                  ++ lib.optionals (!ci) (
                    [
                      # The Python toolchain from uv.lock (lit, pre-commit,
                      # cmake-format, and the docs stack).
                      pythonEnv
                      # uv stays for lockfile maintenance (`uv lock`); the
                      # environment itself is the nix-built pythonEnv above.
                      pkgs.uv
                    ]
                    ++ debuggers
                  );

                  # CMake locates MLIR/LLVM and the HiGHS solver here.
                  CMAKE_PREFIX_PATH = lib.concatStringsSep ":" [
                    "${llvm-mlir}"
                    "${pkgs.highs}"
                  ];
                  CMAKE_BUILD_TYPE = buildType;
                  LLVM_EXTERNAL_LIT = "${pkgs.lit}/bin/lit";

                  shellHook = ''
                    # Keep the host PYTHONPATH out of lit's python. (Only runs
                    # under `nix develop`; direnv does not execute shellHook.)
                    unset PYTHONPATH

                    echo "tamagoyaki ${variant}${lib.optionalString ci " (ci)"} shell ready"
                    echo "  configure: tamagoyaki-configure build"
                    echo "  build:     ninja -C build check-all"
                  '';
                });

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
          # llvm-mlir is published deliberately, not incidentally: downstream
          # repositories (the case studies) build against Tamagoyaki's
          # libraries, so they have to use the MLIR those were compiled
          # against, and re-exporting it here is what lets them do that without
          # building a second LLVM or guessing at a revision.
          packages = {
            default = release.tamagoyaki;
            tamagoyaki = release.tamagoyaki;
            tamagoyaki-debug = debug.tamagoyaki;
            llvm-mlir = release.llvm-mlir;
            llvm-mlir-debug = debug.llvm-mlir;
            inherit pythonEnv;
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
