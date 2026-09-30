{ pkgs, ... }:
{
  packages = [ pkgs.trivy ];

  tasks."check:trivy" = {
    description = "Scan this repository for critical vulnerabilities, secrets, and IaC misconfigurations.";
    exec = ''
      set -euo pipefail
      trivy fs --scanners vuln,misconfig,secret --severity HIGH,CRITICAL \
        --exit-code 1 --no-progress --skip-version-check \
        --skip-dirs .git --skip-dirs .devenv \
        --skip-dirs .direnv --skip-dirs tf/.terraform .
    '';
  };
}
