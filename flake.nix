{
  description = "Tamagoyaki – reproducible evaluation environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
        rustToolchain = pkgs.rust-bin.stable.latest.minimal;
      in {
        devShells.default = pkgs.mkShell {
          name = "tamagoyaki-eval";

          packages = with pkgs; [
            # Build tools
            cmake
            ninja
            gnumake
            git
            m4

            # C/C++ toolchain (uses system clang on macOS via stdenv)
            pkg-config

            # Rust (for Rival)
            rustToolchain

            # Racket (for Herbie)
            racket-minimal
            flex
            bison

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
