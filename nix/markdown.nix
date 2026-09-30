{ pkgs, ... }:
{
  packages = [ pkgs.markdownlint-cli2 ];

  tasks."check:markdown" = {
    description = "Lint repository Markdown files.";
    exec = ''
      set -euo pipefail
      git ls-files --cached --others --exclude-standard -z -- '*.md' | xargs -0 -r markdownlint-cli2
    '';
  };
}
