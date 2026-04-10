{
  description = "Tamagoyaki – reproducible evaluation environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "tamagoyaki-eval";

          packages = with pkgs; [
            # Build tools
            cmake
            ninja
            gnumake
            git

            # C/C++ toolchain (uses system clang on macOS via stdenv)
            pkg-config

            # Rust (for Rival)
            rustc
            cargo

            # Racket (for Herbie)
            racket

            # Python / evaluation pipeline
            python313
            uv
          ];

          shellHook = ''
            echo "tamagoyaki eval shell ready"
            echo "  cmake  : $(cmake --version | head -1)"
            echo "  racket : $(racket --version)"
            echo "  cargo  : $(cargo --version)"
            echo "  uv     : $(uv --version)"
            echo ""
            echo "Run 'make eval-build' to build, 'make eval' to run the evaluation."
          '';
        };
      });
}
