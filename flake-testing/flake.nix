{
  description = "Custom LLVM build using Clang";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # 1. SPECIFY YOUR COMMIT HERE
    # Change the URL to target the specific commit hash you want.
    llvm-project-src = {
      url = "github:llvm/llvm-project/a47d3636f953870d96fb6cc68817365fdad2f9fe";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, llvm-project-src }: 
    let
      system = "x86_64-linux"; # Change to aarch64-linux or aarch64-darwin if needed
      pkgs = import nixpkgs { inherit system; };

      # 2. USE CLANG TO BUILD
      # We use the latest LLVM stdenv available in Nixpkgs so the 
      # compiler doing the building is a modern Clang.
      stdenv = pkgs.llvmPackages_latest.stdenv;

    in {
      packages.${system}.default = stdenv.mkDerivation {
        pname = "llvm-custom";
        version = "custom-commit";

        src = llvm-project-src;

        # The LLVM monorepo contains many projects. 
        # If you only want libLLVM (like the snippet you provided):
        sourceRoot = "source/llvm";
        
        # If you want to build the whole toolchain (clang, lld, etc) from the root, 
        # comment out the sourceRoot above, and uncomment this:
        # cmakeFlags = [ "-S" "../source/llvm" ];

        nativeBuildInputs = with pkgs; [ 
          cmake 
          ninja 
          python3 
        ];

        buildInputs = with pkgs; [ 
          libxml2 
          zlib 
          libffi 
          ncurses 
        ];

        # Standard optimizations
        cmakeBuildType = "Release";

        cmakeFlags = [
          "-DLLVM_INCLUDE_TESTS=OFF"
          "-DLLVM_BUILD_TESTS=OFF"
          "-DLLVM_ENABLE_RTTI=ON"
          "-DLLVM_ENABLE_TERMINFO=OFF"
          
          # If you decided to build the whole toolchain above, specify projects here:
          # "-DLLVM_ENABLE_PROJECTS=clang;lld;polly"
        ];

        # Same hardening disables used in Nixpkgs to prevent build failures
        hardeningDisable = [ "trivialautovarinit" "shadowstack" ];

        meta = with pkgs.lib; {
          description = "Custom LLVM build";
          homepage = "https://llvm.org/";
          platforms = platforms.all;
        };
      };
    };
}
