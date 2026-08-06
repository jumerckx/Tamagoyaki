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
      url = "github:llvm/llvm-project/040a641988f6ed6f4fab250706ca2b620c1de2d8";
      flake = false;
    };
    circt-src = {
      url = "github:llvm/circt/af5369d7ea19dafe8a48d58fa6577e80cde0e883";
      flake = false;
    };
    rival3-src = {
      url = "github:herbie-fp/rival3/8bc5eca5079497a41d37e20a66c833080c92c0ed";
      flake = false;
    };

    # ---- Herbie (Racket) and its package closure -------------------------
    # The evaluation runs `racket -l herbie report` for the accuracy numbers,
    # which needs Herbie plus the Racket packages it depends on. The in-tree
    # CMake path (-DHERBIE_MLIR_BUILD_HERBIE=ON) gets them by cloning Herbie
    # and letting `raco pkg install` resolve the rest from the package
    # catalog -- both of which need network access, so it can never run inside
    # the Nix sandbox. Pinning every source here instead makes the
    # `herbie-racket` prefix a normal, cached, content-addressed derivation.
    #
    # Revisions are the ones `raco` resolved for the pinned Herbie (read back
    # out of racket-pkgs/<ver>/pkgs/pkgs.rktd after a source build). Bumping
    # herbie-src generally means re-reading that file and bumping these too.
    herbie-src = {
      url = "github:herbie-fp/herbie/5500c9684c044bdaca03aee415605f9ac2f05687";
      flake = false;
    };
    racket-fmt-src = {
      url = "github:sorawee/fmt/4e1ed68e596e656960b44a8244bb33eb4e65ec64";
      flake = false;
    };
    # Ships both `pretty-expressive` and `pretty-expressive-lib` as subdirs.
    racket-pretty-expressive-src = {
      url = "github:sorawee/pretty-expressive/9ad7077188c0ab7ac4088a6ee052c64e8eb21925";
      flake = false;
    };
    racket-fpbench-src = {
      url = "github:FPBench/FPBench/7e2b76b1c3b55f923753e23ddfc979f847c50dbb";
      flake = false;
    };
    racket-generic-flonum-src = {
      url = "github:herbie-fp/generic-flonum/e2226376ed7b9bb543ec21606327d52e4077818a";
      flake = false;
    };
    racket-rival-src = {
      url = "github:herbie-fp/rival/4d2334a05338be8df9c6924e30534d693f83267d";
      flake = false;
    };
    # NOTE: the Racket `rival3` package is not a flake input. Unlike the others
    # its catalog entry points at a GitHub *release asset*
    # (releases/latest/download/rival3-racket.zip) rather than a repository, so
    # there is no revision to pin -- "latest" moves under you. It is fetched by
    # pinned release tag with `fetchzip` in the outputs below instead. It is
    # also unrelated to rival3-src above, which is the revision whose Rust C-API
    # gets linked into the C++ side; the two are versioned independently.
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
      herbie-src,
      racket-fmt-src,
      racket-pretty-expressive-src,
      racket-fpbench-src,
      racket-generic-flonum-src,
      racket-rival-src,
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

          nativeLoaderPath = lib.makeLibraryPath [
            pkgs.gmp
            pkgs.mpfr
            pkgs.libmpc
          ];
          loaderPathVar = if isDarwin then "DYLD_LIBRARY_PATH" else "LD_LIBRARY_PATH";
          # A shell line prepending nativeLoaderPath to whatever is already set.
          exportLoaderPath = "export ${loaderPathVar}=\"${nativeLoaderPath}\${${loaderPathVar}:+:\$${loaderPathVar}}\"";

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

          # The Racket `rival3` package, pinned by release tag. v1.0.2 is the
          # release the catalog resolved to for the pinned Herbie (its zip hashes
          # to the checksum recorded in pkgs.rktd), so this reproduces the same
          # prefix a source build produced rather than tracking whatever
          # `releases/latest` points at today.
          #
          # The zip has its package files at the root (info.rkt, main.rkt,
          # private/), hence stripRoot = false.
          racket-rival3-src = pkgs.fetchzip {
            url = "https://github.com/herbie-fp/rival3/releases/download/v1.0.2/rival3-racket.zip";
            hash = "sha256-WwmuJSyEN+/bbvVdw6e0pQ7rjX+87nr387Yug5vAsUg=";
            stripRoot = false;
          };

          # Herbie's egg backend: a Rust cdylib that the `egg-herbie` Racket
          # package dlopen's over FFI. Herbie's own Makefile builds it with an
          # in-tree `cargo build`, which needs crates.io; building it as a
          # normal Rust derivation keeps the Racket prefix below offline.
          egg-herbie-lib = rustPlatform.buildRustPackage {
            pname = "egg-herbie";
            version = "2.3";
            src = herbie-src;

            cargoRoot = "egg-herbie";
            buildAndTestSubdir = "egg-herbie";
            cargoHash = "sha256-jzRiXE7GEYRLlUwbOMwbOS2s3ciPN3tkHkyl0YwIJdY=";
            doCheck = false;

            # Only the cdylib: a `libegg_math.*` glob would also pick up cargo's
            # .rlib and .d, which nothing on the Racket side ever loads. The
            # release dir is target/release or target/<triple>/release depending
            # on whether the build is cross-ish, so search rather than guess.
            installPhase = ''
              runHook preInstall
              mkdir -p $out/lib
              cdylib="$(find target -type f \
                \( -name 'libegg_math.so' -o -name 'libegg_math.dylib' \) \
                -print -quit)"
              if [ -z "$cdylib" ]; then
                echo "egg-herbie: cargo produced no libegg_math cdylib" >&2
                exit 1
              fi
              cp "$cdylib" $out/lib/
              runHook postInstall
            '';
          };

          # Herbie plus its Racket package closure, installed into a
          # self-contained PLTADDONDIR prefix. This is the `racket -l herbie
          # report` half of the evaluation, and the reason the eval used to need
          # an in-tree CMake build: -DHERBIE_MLIR_BUILD_HERBIE=ON produces the
          # same prefix under <build>/herbie_mlir/racket-pkgs, but by cloning
          # Herbie and letting `raco` resolve the rest from the package catalog.
          # Here every source is a pinned flake input and egg-herbie's cdylib is
          # prebuilt, so nothing reaches the network and the result is cached.
          #
          # Use it by pointing PLTADDONDIR at the store path (that is what the
          # Snakefile's `racket_prefix` config does).
          herbie-racket = pkgs.stdenv.mkDerivation {
            pname = "herbie-racket";
            version = "2.3";
            dontUnpack = true;

            nativeBuildInputs = [ pkgs.racket ];

            buildPhase = ''
              runHook preBuild
              export HOME="$TMPDIR/home"
              mkdir -p "$HOME"
              # Some of these packages run code at compile time, which can reach
              # the same dlopen'd libraries the install check needs.
              ${exportLoaderPath}

              # Install directly into $out rather than staging and copying: raco
              # bakes absolute paths into compiled/*.dep, so the prefix it
              # compiles against has to be the prefix it will be used from.
              export PLTADDONDIR="$out"
              mkdir -p "$PLTADDONDIR"

              # `raco pkg install <dir>` takes the package name from the
              # directory's basename, and a bare store path is called
              # "...-source", so stage every source under its real name. The
              # copies also have to be writable: raco compiles in place.
              stage="$TMPDIR/stage"
              mkdir -p "$stage"
              stage_pkg() { # <package-name> <source-dir>
                cp -r "$2" "$stage/$1"
                chmod -R u+w "$stage/$1"
              }

              stage_pkg pretty-expressive-lib ${racket-pretty-expressive-src}/pretty-expressive-lib
              stage_pkg pretty-expressive     ${racket-pretty-expressive-src}/pretty-expressive
              stage_pkg fmt                   ${racket-fmt-src}
              stage_pkg generic-flonum        ${racket-generic-flonum-src}
              stage_pkg fpbench               ${racket-fpbench-src}
              stage_pkg rival                 ${racket-rival-src}
              stage_pkg rival3                ${racket-rival3-src}
              stage_pkg egg-herbie            ${herbie-src}/egg-herbie
              stage_pkg herbie                ${herbie-src}/src

              # egg-herbie/main.rkt resolves the cdylib with
              # (define-runtime-path "target/release/libegg_math.<so>"), i.e. the
              # path cargo would have written it to.
              mkdir -p "$stage/egg-herbie/target/release"
              cp ${egg-herbie-lib}/lib/libegg_math.* "$stage/egg-herbie/target/release/"

              # rival3 ships prebuilt native libraries under upstream Racket's
              # platform names ("aarch64-macosx"), which is not what nixpkgs
              # Racket reports ("aarch64-darwin"); alias the closest arch match
              # so the lookup resolves. Same fix as
              # herbie_mlir/cmake/fix_rival3_native.cmake, applied pre-install so
              # the link is relative and travels with the copy. No-op on Linux,
              # where the two strings already agree.
              subpath="$(racket -e '(displayln (system-library-subpath #f))')"
              nativedir="$stage/rival3/private/native"
              if [ -d "$nativedir" ] && [ ! -e "$nativedir/$subpath" ]; then
                for cand in "$nativedir/''${subpath%%-*}"-*; do
                  if [ -d "$cand" ]; then
                    echo "rival3: aliasing native dir $subpath -> $(basename "$cand")" >&2
                    ln -s "$(basename "$cand")" "$nativedir/$subpath"
                    break
                  fi
                done
              fi

              # One command so raco can satisfy the inter-package dependencies
              # from the set being installed instead of consulting the catalog.
              # Everything else Herbie's info.rkt asks for (math-lib,
              # typed-racket-lib, profile-lib, rackunit-lib, web-server-lib) is
              # already in the full nixpkgs racket at installation scope.
              # --no-docs skips the scribble render: the eval never reads it, and
              # it dominates both build time and output size.
              raco pkg install --batch --no-docs --copy --skip-installed \
                "$stage/pretty-expressive-lib" \
                "$stage/pretty-expressive" \
                "$stage/fmt" \
                "$stage/generic-flonum" \
                "$stage/fpbench" \
                "$stage/rival" \
                "$stage/rival3" \
                "$stage/egg-herbie" \
                "$stage/herbie"

              runHook postBuild
            '';

            # $out is already populated; just drop raco's advisory lock files,
            # which are meaningless in a read-only store path.
            installPhase = ''
              runHook preInstall
              find "$out" -name '.LOCK*' -delete
              runHook postInstall
            '';

            doInstallCheck = true;
            installCheckPhase = ''
              export HOME="$TMPDIR/home"
              export PLTADDONDIR="$out"
              ${exportLoaderPath}
              # Loading the collection is the real test: it dlopen's the egg
              # cdylib and rival3's native library, so a missing or unresolvable
              # library fails here rather than three hours into an eval run.
              racket -e '(dynamic-require (quote egg-herbie) #f)'
              racket -l herbie -- --version
            '';

            meta.platforms = lib.platforms.unix;
          };

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
                    # HiGHS solver for the equivalence-select-ilp pass. Disable
                    # with -DTAMAGOYAKI_ENABLE_HIGHS=OFF to drop this dependency.
                    highs
                  ]);

                  cmakeFlags = [
                    "-DMLIR_DIR=${llvm-mlir}/lib/cmake/mlir"
                    "-DLLVM_DIR=${llvm-mlir}/lib/cmake/llvm"
                    "-DCIRCT_DIR=${circt}/lib/cmake/circt"
                    "-DLLVM_EXTERNAL_LIT=${pkgs.lit}/bin/lit"
                    "-DRIVAL_PREBUILT_LIB=${rival-ffi}/lib/librival3_ffi.a"
                    "-DRIVAL_PREBUILT_INCLUDE=${rival-ffi}/include"
                    "-DCMAKE_INSTALL_RPATH=${llvm-mlir}/lib;${circt}/lib"
                    "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON"
                  ];

                  meta.platforms = lib.platforms.unix;
                }
              );

              # The build the evaluation actually needs: herbie-mlir-opt, and
              # nothing else. rover (and with it the whole CIRCT dependency) and
              # cranelift are dead weight for the eval, so they are switched off
              # -- the point of a separate package is that `nix run .#herbie-eval`
              # gets a cached store path instead of re-configuring and rebuilding
              # a tree every time.
              #
              # Note there is deliberately no -DHERBIE_MLIR_BUILD_HERBIE=ON here:
              # that option clones Herbie and runs `raco pkg install` + `cargo`,
              # none of which work in the network-less Nix sandbox. The Racket
              # side is the `herbie-racket` derivation instead.
              tamagoyaki-eval = tamagoyaki.overrideAttrs (old: {
                pname = "tamagoyaki-eval";
                cmakeFlags = old.cmakeFlags ++ [
                  "-DBUILD_HERBIE_MLIR=ON"
                  "-DBUILD_ROVER_MLIR=OFF"
                  "-DBUILD_CRANELIFT_MLIR=OFF"
                ];
              });

              herbie-eval = pkgs.writeShellApplication {
                name = "herbie-eval";
                runtimeInputs = [
                  tamagoyaki-eval
                  pythonEnv
                  pkgs.racket
                  pkgs.git
                  pkgs.coreutils
                  pkgs.gnutar
                  pkgs.gzip
                ];
                text = ''
                  build_dir="''${BUILD_DIR:-${tamagoyaki-eval}}"
                  racket_prefix="''${RACKET_PREFIX:-${herbie-racket}}"
                  # Relative values are resolved against the repo root by the
                  # Snakefile, so results land at the top level of the checkout.
                  out_dir="''${OUT_DIR:-eval-out}"
                  cores="''${CORES:-1}"

                  if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
                    echo "herbie-eval: not inside a Tamagoyaki checkout." >&2
                    echo "  The pipeline reads herbie_mlir/eval/fpcore and writes" >&2
                    echo "  the output directory ($out_dir), so run it from a clone." >&2
                    exit 1
                  fi

                  export SOURCE_DATE_EPOCH="''${SOURCE_DATE_EPOCH:-315532800}"
                  export PLT_COMPILED_FILE_CHECK=exists
                  ${exportLoaderPath}

                  cd "$repo_root/herbie_mlir/eval"
                  echo "herbie-eval: build_dir=$build_dir" >&2
                  echo "herbie-eval: racket_prefix=$racket_prefix" >&2
                  echo "herbie-eval: out_dir=$out_dir" >&2
                  # A second --config would *replace* ours rather than merge
                  # (argparse overwrites the dest), taking build_dir with it, so
                  # extra entries for sensitivity runs go through EXTRA_CONFIG:
                  #   EXTRA_CONFIG='seed=7 max_nodes=8000' herbie-eval
                  # shellcheck disable=SC2086
                  exec snakemake -j"$cores" --forceall "$@" --resources bench=1 \
                    --config build_dir="$build_dir" racket_prefix="$racket_prefix" \
                      out_dir="$out_dir" ''${EXTRA_CONFIG:-}
                '';
              };

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
                      rustToolchain
                      herbie-setup
                      herbie-eval
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
                    "${pkgs.highs}"
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
                      echo "  eval:      herbie-eval   (run the Herbie-MLIR evaluation; builds nothing)"
                    ''}
                  '';
                }
                // {
                  ${loaderPathVar} = nativeLoaderPath;
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
                circt
                tamagoyaki
                tamagoyaki-eval
                tamagoyaki-configure
                herbie-eval
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
            tamagoyaki-eval = release.tamagoyaki-eval;
            herbie-eval = release.herbie-eval;
            inherit
              rival-ffi
              pythonEnv
              egg-herbie-lib
              herbie-racket
              ;
          };
          devShells = {
            default = release.shell;
            debug = debug.shell;
            ci = release.ciShell;
            docs = release.docsShell;
          };
          apps = {
            herbie-eval = {
              type = "app";
              program = "${release.herbie-eval}/bin/herbie-eval";
            };
          };
        };

      everything = forAllSystems perSystem;
    in
    {
      packages = builtins.mapAttrs (_: v: v.packages) everything;
      devShells = builtins.mapAttrs (_: v: v.devShells) everything;
      apps = builtins.mapAttrs (_: v: v.apps) everything;
    };
}
