{ pkgs, ... }:
{
  packages = with pkgs; [
    gitleaks
    git
    python3
  ];

  git-hooks.hooks.repository-check = {
    enable = true;
    name = "Repository checks";
    entry = "devenv tasks run check:all";
    stages = [ "pre-push" ];
    pass_filenames = false;
  };

  tasks = {
    "check:git" = {
      description = "Scan Git history and the working tree for secrets.";
      exec = ''
        set -euo pipefail
        if [[ "$(git rev-parse --is-shallow-repository)" != false ]]; then
          echo 'Full-history secret scanning requires an unshallow checkout.' >&2
          exit 1
        fi
        gitleaks git --no-banner --redact .
        gitleaks dir --no-banner --redact .
      '';
    };

    "git:update-hooks" = {
      description = "Refresh the pinned git-hooks input and its devenv lock entry.";
      exec = ''
        set -euo pipefail
        rev=$(git ls-remote --exit-code https://github.com/cachix/git-hooks.nix.git refs/heads/master | cut -f1)
        [[ "$rev" =~ ^[a-f0-9]{40}$ ]]
        GIT_HOOKS_REV="$rev" python3 - <<'PY'
        import os
        import pathlib
        import re

        path = pathlib.Path('devenv.yaml')
        before = path.read_text()
        pattern = r'(url: github:cachix/git-hooks\.nix/)[a-f0-9]{40}(?=\s|$)'
        after, count = re.subn(pattern, lambda match: match[1] + os.environ['GIT_HOOKS_REV'], before)
        if count != 1:
            raise SystemExit('Expected exactly one pinned git-hooks input')
        path.write_text(after)
        PY
        devenv --no-tui update git-hooks
      '';
    };
  };
}
