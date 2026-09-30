{ pkgs, ... }:
{
  # Public binary-cache pulls never need a repository credential.
  cachix.pull = [ "quantile-co" ];
  packages = with pkgs; [
    curl
    jq
  ];

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
        # The FlakeHub action exposes an authenticated proxy on loopback only.
        [[ "$MAGIC_NIX_CACHE_ADDRESS" =~ ^127\.0\.0\.1:[0-9]+$ ]]
        # Isolated local stores do not inherit Cachix's runner configuration.
        cachix_key=$(curl --fail --location --silent --show-error \
          https://cachix.org/api/v1/cache/quantile-co |
          jq -er '.publicSigningKeys | map(select(startswith("quantile-co.cachix.org-1:"))) | first // empty')
        cachix_store=$(mktemp -d "$RUNNER_TEMP/cachix-read.XXXXXX")
        nix copy --option trusted-public-keys "$cachix_key" --from https://quantile-co.cachix.org --to "local?root=$cachix_store" "$CACHE_TEST_PATH" -L
        nix path-info --store "local?root=$cachix_store" "$CACHE_TEST_PATH"

        flakehub_store=$(mktemp -d "$RUNNER_TEMP/flakehub-read.XXXXXX")
        # Magic Nix Cache's local proxy can serve unsigned narinfos. Its
        # upstream is authenticated FlakeHub Cache (GHA caching is disabled).
        nix copy --option require-sigs false --from "http://$MAGIC_NIX_CACHE_ADDRESS" --to "local?root=$flakehub_store" "$CACHE_TEST_PATH" -L
        nix path-info --store "local?root=$flakehub_store" "$CACHE_TEST_PATH"
      '';
    };
  };
}
