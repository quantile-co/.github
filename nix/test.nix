_: {
  # `devenv test` is a smoke test for the resolved shell, independent of the
  # repository's source checks. It must not need GCP/GitHub credentials.
  enterTest = ''
    set -euo pipefail
    for tool in tofu tflint nixfmt deadnix statix markdownlint-cli2 yamllint \
      actionlint typos gitleaks opa conftest semgrep trivy vale secretspec; do
      command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }
    done
    tofu version | grep -F 'OpenTofu v1.12.3'
  '';
}
