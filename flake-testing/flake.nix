{
  description = "Minimal LLVM+MLIR+CIRCT (release + debug), cross-platform";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    llvm-project-src = {
      url = "github:llvm/llvm-project/a47d3636f953870d96fb6cc68817365fdad2f9fe";
      flake = false;
    };
    circt-src = {
      url = "github:llvm/circt/96997a18c388f8c7a05344f3f39805bd7856236a";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      llvm-project-src,
      circt-src,
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

          # gdb is broken / unsupported on Darwin in nixpkgs.
          debuggers =
            if isDarwin then
              [ pkgs.lldb ]
            else
              [
                pkgs.gdb
                pkgs.lldb
              ];

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
              ++ lib.optionals isDebug [
                "-DLLVM_PARALLEL_LINK_JOBS=1"
              ];

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
                    "-DLLVM_INCLUDE_UTILS=ON" # tblgen lives here, downstream needs it
                    "-DLLVM_INSTALL_UTILS=OFF"
                    "-DMLIR_INCLUDE_TESTS=OFF"
                    "-DMLIR_INCLUDE_INTEGRATION_TESTS=OFF"
                    "-DMLIR_BUILD_MLIR_C_DYLIB=OFF"
                  ];
                  meta.platforms = lib.platforms.unix;
                  preConfigure = lib.optionalString isDebug ''
                    export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:-} -ffile-prefix-map=$NIX_BUILD_TOP/source=${llvm-project-src}"
                  '';
                  postInstall = lib.optionalString (isDebug && stdenv.hostPlatform.isDarwin) ''
                    for f in $out/lib/lib*.dylib $out/bin/*; do
                      [ -f "$f" ] && [ ! -L "$f" ] || continue
                      file "$f" | grep -q "Mach-O" || continue
                      dsymutil "$f" || true
                    done
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
                    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
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
                    # Flip to ON if you ever want circt-verilog. Pulls in slang.
                    "-DCIRCT_SLANG_FRONTEND_ENABLED=OFF"

                  ];
                  meta.platforms = lib.platforms.unix;
                  preConfigure = lib.optionalString isDebug ''
                    export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:-} -ffile-prefix-map=$NIX_BUILD_TOP/source=${circt-src}"
                  '';
                  postInstall = lib.optionalString (isDebug && stdenv.hostPlatform.isDarwin) ''
                    for f in $out/lib/lib*.dylib $out/bin/*; do
                      [ -f "$f" ] && [ ! -L "$f" ] || continue
                      file "$f" | grep -q "Mach-O" || continue
                      dsymutil "$f" || true
                    done
                  '';
                }
              );

              shell = pkgs.mkShell ({
                packages =
                  with pkgs;
                  [
                    cmake
                    ninja
                  ]
                  ++ debuggers;

                LLVM_DIR = "${llvm-mlir}/lib/cmake/llvm";
                MLIR_DIR = "${llvm-mlir}/lib/cmake/mlir";
                CIRCT_DIR = "${circt}/lib/cmake/circt";
                CMAKE_PREFIX_PATH = "${llvm-mlir}:${circt}";
                CMAKE_BUILD_TYPE = buildType;
              });
            in
            {
              inherit llvm-mlir circt shell;
            };

          release = mkVariant { variant = "release"; };
          debug = mkVariant { variant = "debug"; };
        in
        {
          packages = {
            llvm-mlir = release.llvm-mlir;
            circt = release.circt;
            llvm-mlir-debug = debug.llvm-mlir;
            circt-debug = debug.circt;
            default = release.circt;
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
