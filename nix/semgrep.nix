{ pkgs, ... }:
{
  packages = [ pkgs.semgrep ];

  tasks."check:semgrep" = {
    description = "Test and run local IaC security rules over Terraform sources.";
    exec = ''
      set -euo pipefail
      export SEMGREP_SEND_METRICS=off SEMGREP_ENABLE_VERSION_CHECK=0
      semgrep --test .semgrep --metrics off
      git ls-files --cached --others --exclude-standard -z -- \
        '*.tf' '*.tofu' '*.tf.json' '*.tofu.json' ':(exclude).semgrep/**' | \
        xargs -0 -r semgrep scan --config .semgrep --metrics off --error --strict --scan-unknown-extensions --quiet
    '';
  };
}
