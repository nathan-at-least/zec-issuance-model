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
              inherit (builtins) readFile fromTOML;
              cargoToml = fromTOML (readFile ./Cargo.toml);
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

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          buildInputs = with pkgs; [
            cmake
            expat
            fontconfig.dev
            freetype
          ];

          devShellInputs = with pkgs; [
            cargo
          ];

          rustPkg = pkgs.rustPlatform.buildRustPackage {
            inherit pname version nativeBuildInputs buildInputs;
            src = ./.;
            # cargoBuildFlags = "-p app";

            # patchPhase = ''

            #   set -x

            #   PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 pkg-config --libs --cflags fontconfig

            #   set +x
            #   exit 1
            # '';

            cargoLock = {
              lockFile = ./Cargo.lock;
            };
          };

          plotsPname = "${pname}-plots";
          plotsPkg = pkgs.stdenv.mkDerivation {
            pname = plotsPname;
            inherit version;

            src = ./.;

            builder = writeScript "build_${plotsPname}" ''
              source "$stdenv/setup"

              set -ex

              eval "${rustPkg}/bin/zec-issuance-model"

              basedir="$out/share/doc/"
              mkdir -p "$basedir"
              mv plots "$basedir/${pname}"
              set +x
            '';
          };
        in {
          packages.default = pkgs.symlinkJoin {
            pname = "${pname}-with-plots";
            inherit version;

            paths = [ rustPkg plotsPkg ];
          };

          devShells.default = mkShell {
            inherit buildInputs;
            nativeBuildInputs = nativeBuildInputs ++ devShellInputs;
          };
        }
      )
    )
  );
}
