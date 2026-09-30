{ pkgs, ... }:
{
  packages = [ pkgs.gitleaks ];

  git-hooks.hooks.repository-check = {
    enable = true;
    name = "Repository checks";
    entry = "devenv tasks run check:all";
    stages = [ "pre-push" ];
    pass_filenames = false;
  };

  tasks."check:git" = {
    description = "Scan Git history for committed secrets.";
    exec = ''
      set -euo pipefail
      gitleaks git --no-banner --redact .
    '';
  };
}
