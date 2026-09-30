_: {
  # Public binary-cache pulls never need a repository credential.
  cachix.pull = [ "quantile-co" ];

  tasks = {
    "cache:select-probe" = {
      description = "Add a reference-free store path for both trusted cache publishers.";
      exec = ''
        set -euo pipefail
        path=$(nix store add-path --name quantile-cache-probe README.md)
        printf 'path=%s\n' "$path" >> "$GITHUB_OUTPUT"
      '';
    };

    "cache:verify-reads" = {
      description = "Fetch the published probe from each cache into separate empty stores.";
      exec = ''
        set -euo pipefail
        [[ "$CACHE_TEST_PATH" =~ ^/nix/store/[a-z0-9]{32}-quantile-cache-probe$ ]]
        [[ -n "$MAGIC_NIX_CACHE_ADDRESS" ]]
        # An isolated local store does not inherit this runner's trusted keys.
        keys=$(nix config show trusted-public-keys)

        cachix_store=$(mktemp -d "$RUNNER_TEMP/cachix-read.XXXXXX")
        nix copy --option trusted-public-keys "$keys" --from https://quantile-co.cachix.org --to "local?root=$cachix_store" "$CACHE_TEST_PATH" -L
        nix path-info --store "local?root=$cachix_store" "$CACHE_TEST_PATH"

        flakehub_store=$(mktemp -d "$RUNNER_TEMP/flakehub-read.XXXXXX")
        nix copy --option trusted-public-keys "$keys" --from "http://$MAGIC_NIX_CACHE_ADDRESS" --to "local?root=$flakehub_store" "$CACHE_TEST_PATH" -L
        nix path-info --store "local?root=$flakehub_store" "$CACHE_TEST_PATH"
      '';
    };
  };
}
