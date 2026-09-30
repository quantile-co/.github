# Repository workflow configuration

`check.yaml` runs credential-free `check:all` on PRs. `build.yaml` reruns the
same gate on trusted `main` after merge, then builds the environment for cache
publishing. Workflow YAML must stay a thin wrapper around Devenv tasks defined
under `nix/`. Use YAML for triggers, job ordering, permissions, runner and
cache boundaries, and the few necessary authorization guards. Keep actual
checks and tool configuration in Nix modules. The manual `deploy.yaml` workflow restricts deployment to trusted maintainers
on protected `main`. Deploy plans by default. An authorized maintainer can opt into applying
the saved plan from the same run. The `prod` environment gate runs before the
job. No second approval pause occurs between plan and apply. Preserve
concurrency and state locking, Google Cloud workload identity federation, and
the GitHub token boundary. Never weaken branch protection or authorizations
merely to allow a push.

Validation, deployment, and Dependabot maintenance use Namespace runners.
Separate Namespace cache tags for PR checks, main checks, publishing,
Dependabot, scheduled updates, and deployment form a trust boundary.
Untrusted PR code must never write to the publishing or deployment caches. The Namespace `nix` cache action mounts the
persistent `/nix` store before Determinate Nix installs. PR validation only
pulls from the public `quantile-co` Cachix cache and retains `contents: read`.

After the main-branch gate passes, a separate trusted job builds and publishes
to both Cachix and FlakeHub Cache. This job needs `id-token: write` for
FlakeHub. Supply a per-cache Cachix write token as the GitHub Actions secret
`CACHIX_AUTH_TOKEN`. The trusted publisher alone receives the token. The
Cachix action scans this isolated store at job end instead of installing a
second live upload hook. Manual deployment uses FlakeHub but only pulls from
public Cachix. No deploy-profile secrets may enter the public cache. The
organization manages the platform connections. Define workflow runner labels
and pinned action references here. This repository's `tf/` owns its Actions
enablement and commit pinning. `quantile-q0/q0` owns the organization allowlist
inherited by this repository. GitHub rejects a second repository-level
selected-action list. Update Q0's list when action commits change. Never add
platform-wide resources here.

Dependabot updates GitHub Actions and Terraform dependencies with conventional
commit prefixes. `dependencies.yaml` keeps Dependabot auto-merge and scheduled
Devenv maintenance in separate jobs with event guards and job-level permissions.
The `pull_request_target` job never checks out PR code. It requests auto-merge
only for stable minor/patch updates from the Dependabot bot. Required status
checks and branch protection still gate merges. Maintain review requirements
when adding maintainers.

`update-pins` runs `git:update-hooks`, `nix:update-nixpkgs`, and
`devenv:update-ci` from their owning Nix modules. Each matrix entry has an
isolated Namespace cache, runs `check:all`, and files a separate review-only
PR. No toolchain PR auto-merges. The Dependabot job calls
`dependabot:automerge` from `nix/dependabot.nix`. Both jobs check out trusted
`main`, never the PR head. Checkout drops persisted credentials before
updating inputs. Set and rotate `DEPENDENCY_PR_TOKEN` with `gh secret set`,
not Terraform, to keep its value out of state. A missing token fails closed.
`GITHUB_TOKEN`-created PRs would not trigger validation.

The deploy job sets `SECRETSPEC_PROFILE=deploy` before Devenv runs. Devenv
resolves its required SecretSpec declarations at shell entry. Missing inputs
fail before OpenTofu initialization without a separate secrets check step. PR
validation uses the credential-free default profile. Never interpolate
deployment values into PR jobs or commit them.

Workflow invocations pin the CI Devenv executable by revision. Keep all
workflows on the same revision when updating it. Update the nixpkgs pin and
verify the OpenTofu version when changing the toolchain. The deploy workflow
must continue using the saved plan created in its own run. Never introduce
non-manual production applies, PR cloud credentials, or the old GitLab
HTTP-backend/state-push workflow. `tf/README.md` documents the one-time
local-to-Cloud Storage migration.
