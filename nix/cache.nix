{ pkgs, ... }:
let
  cachixKey = "quantile-co.cachix.org-1:OM+kQzUqP3Ija8QQMUxvQNs97u6PB5/s83ZJe7c9WIQ=";

  # Shared by live readback and local rejection tests. The primary store is
  # also empty, so installable resolution cannot use the runner's own store.
  readCache = pkgs.writeShellScript "read-signed-cache" ''
    set -euo pipefail
    source=$1
    keys=$2
    root=$3
    path=$4
    expected_hash=$5
    netrc=$6
    mkdir "$root"
    store="local?root=$root"
    options=(
      --option require-sigs true
      --option trusted-public-keys "$keys"
      --option substituters ""
      --option fallback false
      --option netrc-file "$netrc"
    )

    printf 'Reading %s from %s into an empty store\n' "$path" "$source"
    nix copy --store "$store" --from "$source" --to "$store" "''${options[@]}" "$path"
    nix store verify --store "$store" --sigs-needed 1 "''${options[@]}" "$path"
    actual_hash=$(nix path-info --store "$store" --json "''${options[@]}" "$path" | jq -er '.[].narHash')
    test "$actual_hash" = "$expected_hash"
    printf 'Verified signature and NAR hash from %s\n' "$source"
  '';

  fixture = pkgs.writeText "cache-signature-fixture" "Signed cache verification fixture.\n";
in
{
  cachix.pull = [ "quantile-co" ];
  packages = [ pkgs.jq ];

  tasks = {
    "cache:select-probe" = {
      description = "Build a reference-free probe unique to this trusted workflow run.";
      exec = ''
        set -euo pipefail
        export CACHE_PROBE_CONTENT="$GITHUB_SHA:$GITHUB_RUN_ID:$GITHUB_RUN_ATTEMPT"
        # An input-addressed derivation: signatures are necessary, not merely
        # the content-addressed-path exemption used by `nix store add-path`.
        path=$(nix build --impure --no-link --print-out-paths --expr '
          derivation {
            name = "quantile-cache-probe";
            system = "${pkgs.stdenv.hostPlatform.system}";
            builder = (builtins.storePath "${pkgs.bash}") + "/bin/bash";
            args = [ "-c" "printf %s \"$probe\" > \"$out\"" ];
            probe = builtins.getEnv "CACHE_PROBE_CONTENT";
          }
        ')
        test -z "$(nix-store --query --references "$path")"
        hash=$(nix path-info --json "$path" | jq -er '.[].narHash')
        printf 'path=%s\nnar-hash=%s\n' "$path" "$hash" >> "$GITHUB_OUTPUT"
      '';
    };

    "cache:verify-reads" = {
      description = "Verify signed downloads from Cachix and FlakeHub independently.";
      exec = ''
        set -euo pipefail
        [[ "$CACHE_TEST_PATH" =~ ^/nix/store/[a-z0-9]{32}-quantile-cache-probe$ ]]
        test -n "$CACHE_TEST_NAR_HASH"
        test "$(nix config show require-sigs)" = true
        # These keys come from the pinned Determinate installer, not narinfo
        # metadata supplied by the cache being tested.
        flakehub_keys=()
        for key in $(nix config show trusted-public-keys); do
          case "$key" in
            cache.flakehub.com-*:*) flakehub_keys+=("$key") ;;
          esac
        done
        test "''${#flakehub_keys[@]}" -gt 0
        netrc=/nix/var/determinate/netrc
        test -r "$netrc"

        work=$(mktemp -d "$RUNNER_TEMP/cache-readback.XXXXXX")
        trap 'rm -rf "$work"' EXIT
        ${readCache} https://quantile-co.cachix.org '${cachixKey}' \
          "$work/cachix" "$CACHE_TEST_PATH" "$CACHE_TEST_NAR_HASH" /dev/null
        ${readCache} https://cache.flakehub.com "''${flakehub_keys[*]}" \
          "$work/flakehub" "$CACHE_TEST_PATH" "$CACHE_TEST_NAR_HASH" "$netrc"
      '';
    };

    "check:cache" = {
      description = "Test signed cache reads and reject unsigned, untrusted, corrupt, or missing data.";
      exec = ''
        set -euo pipefail
        work=$(mktemp -d)
        trap 'rm -rf "$work"' EXIT
        umask 077
        nix key generate-secret --key-name cache-fixture-1 > "$work/key"
        key=$(nix key convert-secret-to-public < "$work/key")
        nix key generate-secret --key-name wrong-fixture-1 > "$work/wrong-key"
        wrong_key=$(nix key convert-secret-to-public < "$work/wrong-key")
        path=${fixture}
        hash=$(nix path-info --json "$path" | jq -er '.[].narHash')
        nix copy --to "file://$work/signed?secret-key=$work/key&compression=none" "$path"
        nix copy --to "file://$work/unsigned?compression=none" "$path"

        ${readCache} "file://$work/signed" "$key" "$work/valid" "$path" "$hash" /dev/null
        reject() {
          label=$1
          source=$2
          trusted_key=$3
          if ${readCache} "$source" "$trusted_key" "$work/read-$label" "$path" "$hash" /dev/null > "$work/$label.log" 2>&1; then
            printf 'Cache verification incorrectly accepted %s\n' "$label" >&2
            exit 1
          fi
          if nix path-info --store "local?root=$work/read-$label" --option substituters "" "$path" > /dev/null 2>&1; then
            printf 'Rejected %s but imported its store path\n' "$label" >&2
            exit 1
          fi
          printf 'Rejected %s without importing the path\n' "$label"
        }
        reject unsigned "file://$work/unsigned" "$key"
        reject wrong-key "file://$work/signed" "$wrong_key"
        cp -a "$work/signed" "$work/corrupt"
        nar=$(awk '/^URL: / { print $2 }' "$work/corrupt/"*.narinfo)
        printf 'corrupt NAR' > "$work/corrupt/$nar"
        reject corrupt "file://$work/corrupt" "$key"
        mkdir "$work/empty"
        printf 'StoreDir: /nix/store\n' > "$work/empty/nix-cache-info"
        # The path exists in the host store, but must not be used as fallback.
        reject missing "file://$work/empty" "$key"
      '';
    };
  };
}
