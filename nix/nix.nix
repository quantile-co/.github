{ pkgs, ... }:
{
  packages = with pkgs; [
    deadnix
    direnv
    nix
    nixfmt
    statix
  ];

  tasks."check:nix" = {
    description = "Check formatting and static analysis for Nix modules.";
    exec = ''
      set -euo pipefail
      git ls-files --cached --others --exclude-standard -z -- '*.nix' | xargs -0 -r nixfmt --check
      git ls-files --cached --others --exclude-standard -z -- '*.nix' | xargs -0 -r deadnix --fail
      git ls-files --cached --others --exclude-standard -z -- '*.nix' | xargs -0 -r -n 1 statix check
    '';
  };

  tasks."nix:update-nixpkgs" = {
    description = "Propose the latest rolling devenv-nixpkgs commit for the whole environment.";
    exec = ''
      set -euo pipefail
      rev=$(git ls-remote --exit-code https://github.com/cachix/devenv-nixpkgs.git refs/heads/rolling | cut -f1)
      [[ "$rev" =~ ^[a-f0-9]{40}$ ]]
      pinned=$(grep -oE 'github:cachix/devenv-nixpkgs/[a-f0-9]{40}' devenv.yaml)
      [[ "$pinned" =~ ^github:cachix/devenv-nixpkgs/[a-f0-9]{40}$ ]]
      old=$(printf '%s' "$pinned" | cut -d/ -f3)
      [[ "$rev" == "$old" ]] && exit 0
      sed -i "s@$pinned@github:cachix/devenv-nixpkgs/$rev@" devenv.yaml
      devenv --no-tui update nixpkgs
    '';
  };
}
