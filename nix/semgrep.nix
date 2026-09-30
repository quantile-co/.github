{ pkgs, ... }:
{
  packages = [ pkgs.semgrep ];

  tasks."check:semgrep" = {
    description = "Test and run local IaC security rules over Terraform sources.";
    exec = ''
      set -euo pipefail
      semgrep --test .semgrep/terraform.tf --config .semgrep/terraform.yml --metrics off
      git ls-files --cached --others --exclude-standard -z -- 'tf/*.tf' | \
        xargs -0 -r semgrep scan --config .semgrep --metrics off --error --quiet
    '';
  };
}
