{ pkgs, ... }:
{
  packages = with pkgs; [
    conftest
    open-policy-agent
  ];

  tasks."check:opa" = {
    description = "Test deployment and cache policies against workflow and shared-action YAML.";
    exec = ''
      set -euo pipefail
      git ls-files --cached --others --exclude-standard -z -- \
        '.github/workflows/*.rego' | xargs -0 -r opa test -v
      git ls-files --cached --others --exclude-standard -z -- \
        '.github/workflows/*.yml' '.github/workflows/*.yaml' \
        '.github/actions/*/action.yml' | \
        xargs -0 -r conftest test --policy .github/workflows
    '';
  };
}
