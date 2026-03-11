{
  description = ":quantile organization profile";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lefthook = pkgs.callPackage ./nix/packages/lefthook.nix { };
      in
      {
        devShells.default = pkgs.mkShell {
          packages =
            (with pkgs; [
              commitizen
              deadnix
              editorconfig-checker
              gitleaks
              go-task
              keep-sorted
              markdownlint-cli2
              nixfmt-rfc-style
              shellcheck
              shfmt
              statix
              taplo
              vale
              yamllint
            ])
            ++ [ lefthook ];

          shellHook = ''
            if [ -d .git ]; then
              lefthook install
            fi
            echo ":quantile organization profile environment loaded"
          '';
        };
      }
    );
}
