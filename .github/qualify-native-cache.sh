#!/usr/bin/env bash
# Temporary production qualification. Remove after cross-run verification.
set -euo pipefail

[[ "${GITHUB_ACTIONS:-}" == true ]]
[[ "${GITHUB_REPOSITORY:-}" == quantile-co/.github ]]
[[ "${GITHUB_REF:-}" == refs/heads/main ]]

state=/nix/.quantile-native-cache-proof
root=/nix/var/nix/gcroots/quantile-native-cache-proof
run="${GITHUB_RUN_ID:?}-${GITHUB_RUN_ATTEMPT:?}"

if [[ ! -e "$state" ]]; then
  [[ ! -e "$root" && ! -L "$root" ]]
  bash_path=$(readlink -f "$(type -P bash)")
  export PROOF_BASH="${bash_path%/bin/bash}" PROOF_RUN="$run"
  # An input-addressed output, not a content-addressed source that can bypass
  # signature verification. All builder dependencies are already in the shell.
  # shellcheck disable=SC2016 # Expansion belongs to Nix and the builder shell.
  path=$(nix-build --no-out-link --option substituters '' --option builders '' --expr '
    let bash = builtins.storePath (builtins.getEnv "PROOF_BASH");
    in derivation {
      name = "quantile-native-cache-proof-" + builtins.getEnv "PROOF_RUN";
      system = builtins.currentSystem;
      builder = "${bash}/bin/bash";
      args = [ "-c" "printf \"%s\\n\" \"$marker\" > \"$out\"" ];
      marker = builtins.getEnv "PROOF_RUN";
    }
  ')
  nix-store --check-validity "$path"
  ln -s "$path" "$root"
  printf '%s\n%s\n' "$path" "$run" > "$state"
  printf 'NATIVE_CACHE_PROOF_SEEDED run=%s path=%s\n' "$run" "$path"
  # The stock Cachix post action uploads it; Namespace commits the snapshot.
  exit 0
fi

mapfile -t saved < "$state"
[[ "${#saved[@]}" == 2 ]]
path=${saved[0]}
previous=${saved[1]}
[[ "$path" =~ ^/nix/store/[a-z0-9]{32}-quantile-native-cache-proof-[0-9]+-[0-9]+$ ]]
[[ "$previous" =~ ^[0-9]+-[0-9]+$ && "$previous" != "$run" ]]
[[ "$(readlink "$root")" == "$path" ]]
[[ -f "$path" && "$(< "$path")" == "$previous" ]]

# Success without substitution or builders proves restored store metadata too.
nix-store --check-validity "$path"
nix-store --realise "$path" --option substitute false --option max-jobs 0 --option builders ''
printf 'NATIVE_CACHE_PROOF_RESTORED previous=%s current=%s path=%s\n' "$previous" "$run" "$path"

nix path-info --store https://quantile-co.cachix.org "$path"
printf 'NATIVE_CACHE_PROOF_UPLOADED path=%s\n' "$path"
[[ "$(nix config show require-sigs)" == true ]]
keys=$(nix config show trusted-public-keys)
[[ "$keys" == *'quantile-co.cachix.org-1:OM+kQzUqP3Ija8QQMUxvQNs97u6PB5/s83ZJe7c9WIQ='* ]]
[[ "$keys" == *'cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY='* ]]

# Remove only this run's disposable fixture, never an environment dependency.
rm -- "$root"
nix-store --delete "$path"
[[ ! -e "$path" ]]
if nix-store --check-validity "$path" 2>/dev/null; then
  echo 'Fixture unexpectedly remains registered.' >&2
  exit 1
fi

# Use the real configuration, not an injected substitute URL or signing key.
# No local or remote builder can hide a failed download.
nix-store --realise "$path" --option max-jobs 0 --option builders '' \
  2>&1 | tee "$RUNNER_TEMP/quantile-native-substitution.log"
grep -F "from 'https://quantile-co.cachix.org'" "$RUNNER_TEMP/quantile-native-substitution.log"
nix-store --check-validity "$path"
[[ "$(< "$path")" == "$previous" ]]
printf 'NATIVE_CACHE_PROOF_SUBSTITUTED path=%s\n' "$path"

nix-store --delete "$path"
rm -- "$state"
echo 'NATIVE_CACHE_PROOF_PASSED: cross-run store/database reuse, upload, signed automatic substitution.'
