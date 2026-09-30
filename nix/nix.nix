{ pkgs, ... }:
{
  packages = with pkgs; [
    deadnix
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
}
