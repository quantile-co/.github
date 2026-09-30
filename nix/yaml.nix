{ pkgs, ... }:
{
  packages = [ pkgs.yamllint ];

  tasks."check:yaml" = {
    description = "Lint repository YAML files.";
    exec = ''
      set -euo pipefail
      # Do not reformat the vendored upstream Vale package as first-party YAML.
      git ls-files --cached --others --exclude-standard -z -- \
        '*.yaml' '*.yml' ':(exclude).vale/styles/Google/**' | \
        xargs -0 -r yamllint -c .yamllint.yaml
    '';
  };
}
