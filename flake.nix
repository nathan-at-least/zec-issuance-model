{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }: (
    flake-utils.lib.eachDefaultSystem (
      system: (
        let
          pname = "zec-issuance-plots";
          version = (
            let
              inherit (builtins) readFile fromToml;
              cargoToml = fromToml (readFile ./Cargo.toml);
            in 
              cargoToml.package.version
          );

          overlays = [];
          pkgs = import nixpkgs {
            inherit system overlays;
          };

          inherit (pkgs)
            # nix plumbing:
            mkShell
            writeScript
          ;
        in {
          packages.default = pkgs.stdenv.mkDerivation {
            inherit pname version;

            src = ./.;
            builder = writeScript "build_${pname}" ''
              source "$stdenv/setup"

              echo 'FIXME: nix package build is not yet implemented.'
              exit 1
            '';
          };

          devShells.default = mkShell {
            buildInputs = with pkgs; [
              cargo
              cmake
              expat
              # file
              freetype
              pkg-config
            ];
          };
        }
      )
    )
  );
}
