{ pkgs, ... }:
{
  packages = [ pkgs.typos ];

  tasks."check:typos" = {
    description = "Check repository files for typos.";
    exec = ''
      set -euo pipefail
      # Vale's vendored regex rules are third-party source, not local prose.
      git ls-files --cached --others --exclude-standard -z -- \
        . ':(exclude).vale/styles/Google/**' | xargs -0 -r typos
    '';
  };
}
