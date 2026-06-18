{
  description = "Tamagoyaki - MLIR-based equality saturation framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      url = "github:llvm/llvm-project/b7152ff7026a05282b6ae91ccf150ede0217b08a";
      flake = false;
    };
    circt-src = {
      url = "github:llvm/circt/13a483ce96d6e020db9c7a70ae2971fb5a25134e";
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
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
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

          # nixpkgs Racket reports its platform subpath as "<arch>-darwin", but
          # Herbie's `egg-herbie` package is a redirect that gates its prebuilt
          # binary dependency on the upstream Racket string ("<arch>-macosx").
          # That guard never matches under nixpkgs Racket on macOS, so
          # `raco pkg install herbie` silently omits the binary package and the
          # `egg-herbie` collection ends up missing. Naming the prebuilt package
          # for this system explicitly sidesteps the guard. On Linux the strings
          # agree, so the default dependency resolution already works ("").
          eggHerbiePkg =
            if system == "aarch64-darwin" then
              "egg-herbie-macosm1"
            else if system == "x86_64-darwin" then
              "egg-herbie-osx"
            else
              "";

          # One-shot, idempotent helper: install Herbie into the user's Racket
          # package scope together with the correct prebuilt egg-herbie for this
          # system, then confirm the `egg-herbie` collection actually loads (it
          # dlopen's a Rust cdylib via FFI). Run once per machine.
          herbie-setup = pkgs.writeShellScriptBin "herbie-setup" ''
            set -euo pipefail
            want="herbie ${eggHerbiePkg}"
            echo "herbie-setup: ensuring Herbie + egg-herbie are installed ..." >&2
            raco pkg install --auto --skip-installed $want
            if racket -e '(dynamic-require (quote egg-herbie) #f)' >/dev/null 2>&1; then
              echo "herbie-setup: egg-herbie OK. Run: racket -l herbie -- web --quiet" >&2
            else
              echo "herbie-setup: egg-herbie collection still missing after install." >&2
              exit 1
            fi
          '';

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

          # The whole Python toolchain, built from pyproject.toml + uv.lock via
          # uv2nix. One source of truth shared with `uv`: the runtime deps
          # (xdsl, numpy, pandas, matplotlib, snakemake), the dev tooling (lit,
          # pre-commit, cmake-format) and the docs group (sphinx, furo, breathe,
          # ...) all come from the lockfile. `deps.all` pulls in every
          # optional-dependency group, so the docs build needs no separate env.
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
          # Single venv used by every shell that needs Python.
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
                let
                  # gmp/mpfr/libmpc are dlopen'd at runtime (Racket/Herbie and
                  # rival), so they must be on the loader path. Set this as a
                  # declarative env var rather than in shellHook: `nix develop`
                  # runs shellHook, but direnv's `use flake` does not, so a
                  # shellHook export is invisible under direnv.
                  loaderPath = lib.makeLibraryPath [
                    pkgs.gmp
                    pkgs.mpfr
                    pkgs.libmpc
                  ];
                in
                (pkgs.mkShell.override { inherit stdenv; }) ({
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
                    pythonEnv
                  ]
                  ++ lib.optionals (!ci) (
                    [
                      rustToolchain
                      herbie-setup
                      # The full Python toolchain from uv.lock (xdsl, snakemake,
                      # lit, pre-commit, cmake-format, plotting + docs deps).
                      pythonEnv
                    ]
                    ++ (with pkgs; [
                      racket
                      # uv stays for lockfile maintenance (`uv lock`); the
                      # environment itself is the nix-built pythonEnv above.
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
                    # Keep the host PYTHONPATH out of lit's python. (Only runs
                    # under `nix develop`; direnv does not execute shellHook.)
                    unset PYTHONPATH

                    echo "tamagoyaki ${variant}${lib.optionalString ci " (ci)"} shell ready"
                    echo "  configure: tamagoyaki-configure build"
                    echo "  build:     ninja -C build check-all"
                    ${lib.optionalString (!ci) ''
                      echo "  herbie:    herbie-setup  (once; then racket -l herbie -- web --quiet)"
                    ''}
                  '';
                }
                // (
                  if isDarwin then
                    { DYLD_LIBRARY_PATH = loaderPath; }
                  else
                    { LD_LIBRARY_PATH = loaderPath; }
                ));

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
            inherit rival-ffi pythonEnv;
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
