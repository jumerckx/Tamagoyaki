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

            # Native libs needed by Racket packages pulled in by Herbie
            gmp
            mpfr
            fontconfig
            cairo
            pango
            libjpeg
            libpng
            zlib

            # Python / evaluation pipeline
            python313
            uv
          ];

          # Racket's FFI needs to dlopen native libs (libmpfr, libcairo, …).
          # In a Nix shell these live in the Nix store; expose them via lib path.
          RACKET_FFI_LIB_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
            gmp mpfr
            fontconfig cairo pango
            glib
            harfbuzz
            freetype
            fribidi
            pixman
            expat
            libjpeg libpng zlib
          ]);

          shellHook = ''
            if [[ "$(uname)" == "Darwin" ]]; then
              export DYLD_FALLBACK_LIBRARY_PATH="$RACKET_FFI_LIB_PATH''${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
            else
              export LD_LIBRARY_PATH="$RACKET_FFI_LIB_PATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            fi
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
