{ pkgs, ... }:
{
  packages = [ pkgs.gh ];

  # The workflow checks the bot identity and checks out trusted main, not PR code.
  tasks."dependabot:automerge" = {
    description = "Enable auto-merge only for stable Dependabot minor or patch updates.";
    exec = ''
      set -euo pipefail
      case "$UPDATE_TYPE" in
        version-update:semver-minor|version-update:semver-patch) ;;
        *) exit 0 ;;
      esac
      # An exact stable SemVer rejects pre-1.0, pre-releases, and grouped values.
      [[ "$PREVIOUS_VERSION" =~ ^v?[1-9][0-9]*[.][0-9]+[.][0-9]+$ ]] || exit 0
      [[ "$NEW_VERSION" =~ ^v?[1-9][0-9]*[.][0-9]+[.][0-9]+$ ]] || exit 0
      gh pr merge --auto --squash "$PR_URL"
    '';
  };
}
