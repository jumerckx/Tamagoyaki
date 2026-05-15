{
  description = "Minimal LLVM+MLIR+CIRCT build for a downstream consumer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    llvm-project-src = {
      url = "github:llvm/llvm-project/a47d3636f953870d96fb6cc68817365fdad2f9fe";
      flake = false;
    };

    # IMPORTANT: pick a CIRCT commit whose `llvm` submodule points at the
    # llvm-project commit above (or close enough that the APIs match).
    # Otherwise you'll hit header/ABI breakage at CIRCT compile time.
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
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Build with a modern Clang from nixpkgs.
      stdenv = pkgs.llvmPackages_latest.stdenv;

      # Flags shared by both derivations so LLVM and CIRCT agree on ABI
      # (assertions especially — mismatched assertion settings change struct
      # layouts and corrupt linkage silently).
      commonCmakeFlags = [
        "-DLLVM_ENABLE_ASSERTIONS=OFF"
        "-DLLVM_ENABLE_RTTI=ON"
        "-DLLVM_ENABLE_TERMINFO=OFF"
        "-DLLVM_ENABLE_ZSTD=OFF"
        "-DLLVM_TARGETS_TO_BUILD=Native"
        # Link against a single libLLVM.so instead of dozens of static libs.
        # Shrinks the closure dramatically.
        "-DLLVM_LINK_LLVM_DYLIB=ON"
      ];

      llvm-mlir = stdenv.mkDerivation {
        pname = "llvm-mlir";
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

        cmakeBuildType = "Release";

        cmakeFlags = commonCmakeFlags ++ [
          "-DLLVM_ENABLE_PROJECTS=mlir"

          # Actually produce the shared libLLVM.so the flag above links to.
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

        hardeningDisable = [
          "trivialautovarinit"
          "shadowstack"
        ];

        meta = with pkgs.lib; {
          description = "LLVM + MLIR (libraries only, for downstream cmake)";
          homepage = "https://mlir.llvm.org/";
          platforms = platforms.unix;
        };
      };

      circt = stdenv.mkDerivation {
        pname = "circt";
        version = "custom";

        src = circt-src;
        # CIRCT's repo root has its own CMakeLists.txt for the standalone
        # build flow — no sourceRoot tweaking needed.

        nativeBuildInputs =
          with pkgs;
          [
            cmake
            ninja
            python3
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
        # propagate llvm-mlir so downstream `nix build .#circt` users
        # automatically pull MLIR/LLVM into their closure.
        propagatedBuildInputs = [ llvm-mlir ];
        buildInputs = with pkgs; [
          zlib
          libffi
        ];

        cmakeBuildType = "Release";

        cmakeFlags = commonCmakeFlags ++ [
          "-DMLIR_DIR=${llvm-mlir}/lib/cmake/mlir"
          "-DLLVM_DIR=${llvm-mlir}/lib/cmake/llvm"

          "-DCIRCT_INCLUDE_TESTS=OFF"
          "-DCIRCT_INCLUDE_INTEGRATION_TESTS=OFF"
          "-DCIRCT_BINDINGS_PYTHON_ENABLED=OFF"
          # Flip to ON if you ever want circt-verilog. Pulls in slang.
          "-DCIRCT_SLANG_FRONTEND_ENABLED=OFF"
        ];

        hardeningDisable = [
          "trivialautovarinit"
          "shadowstack"
        ];

        meta = with pkgs.lib; {
          description = "CIRCT built against an external LLVM/MLIR";
          homepage = "https://circt.llvm.org/";
          platforms = platforms.unix;
        };
      };

    in
    {
      packages.${system} = {
        inherit llvm-mlir circt;
        default = circt;
      };

      # `nix develop` gives you cmake + ninja with every *_DIR your
      # project needs already exported.
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          cmake
          ninja
        ];

        LLVM_DIR = "${llvm-mlir}/lib/cmake/llvm";
        MLIR_DIR = "${llvm-mlir}/lib/cmake/mlir";
        CIRCT_DIR = "${circt}/lib/cmake/circt";
        CMAKE_PREFIX_PATH = "${llvm-mlir}:${circt}";
        LD_LIBRARY_PATH = "${llvm-mlir}/lib:${circt}/lib";
      };
    };
}
