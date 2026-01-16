{
  description = "A devShell example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kast.url = "github:kast-lang/kast";
    # kast.url = "git+file:/home/kuviman/projects/kast-lang/kast";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ ];
        pkgs = import inputs.nixpkgs { inherit system overlays; };
        kast = inputs.kast.packages.${system}.default;
        package = pkgs.stdenv.mkDerivation {
          pname = "kuvibot";
          version = "0.1.0";
          src = ./.;
          buildInputs = [ kast ];
          buildPhase = ''
            kast compile --target js --output target/main.mjs src/main.ks
          '';
          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/lib
            cp target/main.mjs $out/lib/main.mjs
            cp refresh.sh $out/lib/refresh.sh
            cat > $out/bin/kuvibot <<'EOF'
            #!${pkgs.bash}/bin/bash
            BIN="$(dirname "$0")"
            set -e
            . $BIN/../lib/refresh.sh
            ${pkgs.nodejs}/bin/node $BIN/../lib/main.mjs
            EOF
            chmod +x $out/bin/kuvibot
          '';
        };
      in
      with pkgs; {
        apps.default = {
          type = "app";
          program = "${package}/bin/kuvibot";
        };
        devShells.default = mkShell {
          packages = [
            (pkgs.writeShellScriptBin "kast" ''
              systemd-run --user --scope -p MemoryMax=10G \
                rlwrap ${kast}/bin/kast "$@"
            '')
            rlwrap
            nixfmt-classic
            nodejs
          ];
        };
      });
}
