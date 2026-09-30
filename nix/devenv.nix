{ pkgs, ... }:
{
  packages = with pkgs; [
    gh
    git
    ripgrep
  ];

  tasks."devenv:update-ci" = {
    description = "Propose the latest stable Devenv release commit for every CI workflow.";
    exec = ''
      set -euo pipefail
      tag=$(gh api repos/cachix/devenv/releases/latest --jq .tag_name)
      [[ "$tag" =~ ^v[0-9]+[.][0-9]+[.][0-9]+$ ]]
      rev=$(git ls-remote --exit-code https://github.com/cachix/devenv.git "refs/tags/$tag" "refs/tags/$tag^{}" | awk -v name="refs/tags/$tag" '$2 == name { tag = $1 } $2 == name "^{}" { commit = $1 } END { print commit == "" ? tag : commit }')
      [[ "$rev" =~ ^[a-f0-9]{40}$ ]]

      pinned=$(rg -o --no-filename 'github:cachix/devenv/[a-f0-9]{40}' .github/workflows/*.yaml | sort -u)
      [[ "$pinned" =~ ^github:cachix/devenv/[a-f0-9]{40}$ ]]
      old=$(printf '%s' "$pinned" | cut -d/ -f3)
      [[ "$rev" == "$old" ]] && exit 0

      # A new stable release must descend from the current CI revision.
      status=$(gh api "repos/cachix/devenv/compare/$old...$rev" --jq .status)
      [[ "$status" == ahead ]]
      rg -l -0 --fixed-strings "$pinned" .github/workflows/*.yaml |
        xargs -0 -r sed -i "s@$pinned@github:cachix/devenv/$rev@g"
    '';
  };
}
