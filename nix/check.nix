_: {
  tasks."check:all" = {
    description = "Run all local checks without cloud credentials or a remote state backend.";
    exec = ''
      set -euo pipefail
      devenv tasks run --show-output check:tf
      devenv tasks run --show-output check:markdown
      devenv tasks run --show-output check:yaml
      devenv tasks run --show-output check:github
      devenv tasks run --show-output check:nix
      devenv tasks run --show-output check:typos
      devenv tasks run --show-output check:opa
      devenv tasks run --show-output check:semgrep
      devenv tasks run --show-output check:trivy
      devenv tasks run --show-output check:vale
      devenv tasks run --show-output check:git
      devenv test
    '';
  };
}
