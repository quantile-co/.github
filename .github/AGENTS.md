# Repository workflow configuration

`check.yaml` runs credential-free `check:all` once on PRs. Protected main
requires its `All` status. `build.yaml` smoke-tests and publishes only trusted
main outputs, without repeating the full PR gate. Workflow YAML must stay a thin wrapper around Devenv tasks defined
under `nix/`. Use YAML for triggers, job ordering, permissions, runner and
cache boundaries, and the few necessary authorization guards. Keep actual
checks and tool configuration in Nix modules. Manual `plan.yaml` and
`apply.yaml` restrict repository changes to trusted maintainers on protected
`main`. Plan never applies. Apply creates and applies a saved plan in its own
job, without transferring sensitive plan artifacts. The `prod` environment
gate runs before either job. Preserve shared concurrency and state locking,
Google Cloud workload identity federation, and the GitHub token boundary.
Never weaken branch protection or authorizations merely to allow a push.

Validation, deployment, and Dependabot maintenance use Namespace runners.
Separate Namespace cache tags for PR checks, main checks, publishing,
Dependabot, scheduled updates, and deployment form a trust boundary.
Untrusted PR code must never write to the publishing or deployment caches.
Namespace mounts `/nix` before installation. Discard a restored Nix
installation receipt so Determinate Nix installs and starts a new daemon on
each fresh runner while reusing the persisted store and database. PR
validation only pulls from public Cachix and retains `contents: read`.

After a checked PR merges, a trusted Build job publishes Nix paths to Cachix
and FlakeHub Cache. A separate job reads a reference-free
probe from each cache into a fresh store after publishing finishes. Both jobs
need `id-token: write` for FlakeHub. Supply a per-cache Cachix write token as
the GitHub Actions secret
`CACHIX_AUTH_TOKEN`. The trusted publisher alone receives the token. The
Cachix action scans this isolated store at job end instead of installing a
second live upload hook. Plan and Apply use FlakeHub but only pull from
public Cachix. No prod-profile secrets may enter the public cache. The
organization manages the platform connections. Define workflow runner labels
and pinned action references here. This repository's `tf/` owns its Actions
enablement and commit pinning. `quantile-q0/q0` owns the organization allowlist
inherited by this repository. GitHub rejects a second repository-level
selected-action list. Update Q0's list when action commits change. Never add
platform-wide resources here.

Dependabot updates GitHub Actions and Terraform dependencies with conventional
commit prefixes. `dependencies.yaml` runs scheduled and manual review-only
updates. `dependabot.yaml` handles bot PRs. Its `pull_request_target` job
never checks out PR code. It requests auto-merge only for stable minor/patch
updates from the Dependabot bot. Non-bot PRs may display one skipped
Dependabot job, but no scheduled dependency jobs. Required status checks and
branch protection still gate merges. Maintain review requirements when
adding maintainers.

The dependency matrix runs `git:update-hooks`, `nix:update-nixpkgs`, and
`devenv:update-ci` from their owning Nix modules. Each matrix entry has an
isolated Namespace cache, runs `check:all`, and files a separate review-only
PR. No toolchain PR auto-merges. The Dependabot job calls
`dependabot:automerge` from `nix/dependabot.nix`. Both jobs check out trusted
`main`, never the PR head. Checkout drops persisted credentials before
updating inputs. Store the dedicated pull request token as
`GITHUB_DEPENDENCY_PR_TOKEN` with `gh secret set`, not Terraform. The workflow
temporarily accepts the existing `DEPENDENCY_PR_TOKEN`. GitHub won't let you
read back or rename stored secret values, so copy the token from its secure
source. Remove the fallback only after a run files a PR with the new name. A
missing token fails closed.
`GITHUB_TOKEN`-created PRs would not trigger validation.

Plan and Apply set `SECRETSPEC_PROFILE=prod` before Devenv runs. Devenv
resolves its required SecretSpec declarations at shell entry. Missing inputs
fail before OpenTofu initialization without a separate secrets check step. PR
validation uses the credential-free default profile. Never interpolate
deployment values into PR jobs or commit them.

Workflow invocations pin the CI Devenv executable by revision. Keep all
workflows on the same revision when updating it. Update the nixpkgs pin and
verify the OpenTofu version when changing the toolchain. Apply must continue
using the saved plan created in its own job. Never introduce
non-manual production applies, PR cloud credentials, or the old GitLab
HTTP-backend/state-push workflow. `tf/README.md` documents the one-time
local-to-Cloud Storage migration.
