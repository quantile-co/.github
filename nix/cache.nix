{ lib, pkgs, ... }:
{
  cachix.pull = [ "quantile-co" ];

  tasks = {
    "cache:sync" = {
      description = "Flush the active Nix store and database before the runner exits.";
      exec = "sync -f /nix";
    };

    "cache:roots" = {
      description = "Select this environment's closures for Cachix publication, including warm paths.";
      exec = ''
        set -euo pipefail
        paths=()
        for root in .devenv/gc/*; do
          test -L "$root" || continue
          path=$(readlink -f "$root")
          nix-store --check-validity "$path"
          paths+=("$path")
        done
        test "''${#paths[@]}" -gt 0
        printf 'paths=%s\n' "''${paths[*]}" >> "$GITHUB_OUTPUT"
        printf 'cachix-bin=%s\n' '${lib.getExe pkgs.cachix}' >> "$GITHUB_OUTPUT"
      '';
    };

    "check:cache" = {
      description = "Check Nix signature enforcement and public cache signing keys.";
      exec = ''
        set -euo pipefail
        test "$(nix config show require-sigs)" = true || {
          echo 'Nix signature enforcement must remain enabled.' >&2
          exit 1
        }
        if [[ "''${GITHUB_ACTIONS:-false}" == true ]]; then
          keys=$(nix config show trusted-public-keys)
          [[ "$keys" == *'quantile-co.cachix.org-1:OM+kQzUqP3Ija8QQMUxvQNs97u6PB5/s83ZJe7c9WIQ='* && "$keys" == *'cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY='* ]] || {
            echo 'CI setup must retain the Cachix and NixOS signing keys.' >&2
            exit 1
          }
        fi
      '';
    };
  };
}
