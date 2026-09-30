{ pkgs, ... }:
{
  packages = with pkgs; [
    conftest
    open-policy-agent
  ];

  tasks."check:opa" = {
    description = "Test local deployment-policy rules against GitHub workflow YAML.";
    exec = ''
      set -euo pipefail
      git ls-files --cached --others --exclude-standard -z -- \
        '.github/workflows/*.rego' | xargs -0 -r opa test -v
      git ls-files --cached --others --exclude-standard -z -- \
        '.github/workflows/*.yml' '.github/workflows/*.yaml' | \
        xargs -0 -r conftest test --policy .github/workflows
    '';
  };
}
