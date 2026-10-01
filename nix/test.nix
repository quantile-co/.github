_: {
  # `devenv test` is a smoke test for the resolved shell, independent of the
  # repository's source checks. It must not need GCP/GitHub credentials.
  enterTest = ''
    set -euo pipefail
    for tool in tofu tflint nixfmt deadnix statix markdownlint-cli2 yamllint \
      actionlint shellcheck typos gitleaks opa conftest semgrep trivy vale secretspec \
      nix nix-store devenv direnv git gh gcloud jq python3 rg cachix \
      bash awk sed grep find xargs cut sort readlink rm; do
      path=$(type -P "$tool") || { echo "Missing tool: $tool" >&2; exit 1; }
      case "$(readlink -f "$path")" in
        /nix/store/*) ;;
        *) echo "Tool is not from Nix: $tool ($path)" >&2; exit 1 ;;
      esac
    done
    tofu version | grep -E '^OpenTofu v[0-9]+\.[0-9]+\.[0-9]+'
  '';
}
