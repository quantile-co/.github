{ pkgs, ... }:
{
  packages = [ pkgs.actionlint ];

  tasks."check:github" = {
    description = "Check GitHub Actions workflow semantics.";
    exec = ''
      set -euo pipefail
      # Namespace runner labels are valid custom labels, not known GitHub-hosted labels.
      actionlint -ignore 'label "(nscloud-|namespace-profile-)'
    '';
  };
}
