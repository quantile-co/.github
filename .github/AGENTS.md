# Repository workflow configuration

**README edits:** be very judicious. Ask the user and get explicit approval
before editing any README. Propose only necessary, succinct changes. Keep
workflow details and agent implementation guidance in `AGENTS.md`, not READMEs.

Use these shared verb–noun names:

- Check → All
- Build → Nix caches
- Plan/Apply → Infrastructure
- Update → GitHub Actions and OpenTofu providers
- Update → Nix inputs and Devenv CLI

Keep the protected job IDs unchanged.
`namespace-profile-quantile` is the shared Restricted runner profile. Its cache
volume must set `allow_commit_from_branch: ["main"]`, with default profile and
repository isolation. The creation command is in the
[Q0 Day 0 runbook](https://github.com/quantile-q0/q0#day-0-runbook). This repository
consumes the profile, not its management credentials. Configure the profile
before these workflows run.

`check.yaml` has exactly one job, All, which runs credential-free `check:all`
once on PRs. Don't add tool-specific Check jobs or an aggregate gate. Protected
main requires its `All` status. Check and the review-only updater fetch full Git
history for Gitleaks. The secret-scanning task rejects shallow checkouts.
`build.yaml` smoke-tests and publishes only trusted
main outputs, without repeating the full PR gate. Workflow YAML must stay a thin wrapper around Devenv tasks defined
under `nix/`. Use YAML for triggers, job ordering, permissions, runner and
cache boundaries, and the few necessary authorization guards. Keep actual
checks and tool configuration in Nix modules. Manual `plan.yaml` and
`apply.yaml` restrict repository changes to trusted maintainers on protected
`main`. Plan never applies. Apply creates and applies a saved plan in its own
job, without transferring sensitive plan artifacts. The `prod` environment
gate restricts branches before either job, without approval reviewers. The
workflow policy rejects missing environments, altered authorization guards,
and renamed or additional deployment jobs. Preserve shared concurrency and state locking,
Google Cloud workload identity federation, and the GitHub token boundary.
Never weaken branch protection or authorizations merely to allow a push.

Validation, deployment, and maintenance use standard Nix on Namespace runners.
Call pinned stock actions directly in workflows. Mount `/nix` with the pinned
Namespace action before the Cachix installer, using `--no-daemon`. This reuses the
active store and database and recreates the user profile on each fresh runner.
Keep the integration's spacectl version pinned and ignore the host binary.
Don't add an installer wrapper, copy the store elsewhere, or delete installer
receipts. Namespace decides which snapshots persist. The mount action's post
step isn't the publisher. Tags alone aren't authorization.

Any job on protected main, including Plan and Apply, may retain its Nix changes.
Other branches use private writable copies. Namespace discards their changes.
A PR event alone isn't a reason to reject publication by this repository's main.
Only the input-update matrix uses `nscloud-cache-exp-do-not-commit`: it evaluates
new inputs before review, even though its workflow starts from main.
`cache:sync` flushes the active filesystem after successful work. Single-user
Nix leaves no daemon running during snapshot completion. Treat snapshots as
optional. Signed remote substitution handles missing store paths.

Keep `require-sigs = true`. Configure public Cachix reads through additive
`extra-substituters` and `extra-trusted-public-keys` installer settings, retaining
the NixOS key. PR checks verify both keys. Only Build's guarded `publish-caches`
job receives `CACHIX_AUTH_TOKEN` and runs `cachix/cachix-action`.
Build smoke-tests the environment, then `cache:roots` selects its devenv GC
roots and a pinned Cachix executable for the action's `pathsToPush` and
`cachixBin` inputs. This publishes warm as well as newly built paths without
an extra uploader or repeating the full gate. Keep `skipAddingSubstituter: true`.

Only Build publishes to remote Cachix. Namespace snapshot commits are separate.
PR checks have no cloud identity or remote cache write credentials. Only Plan and
Apply request OpenID Connect for Google Cloud. This repository no longer uses Determinate or FlakeHub.
Keep commissioning probes, the readback job, and custom signature fixtures out
of routine CI. Retain signature enforcement, expected-key checks, and lightweight
workflow policy tests. Never place production credentials in store paths.
Checkout doesn't persist its Git credential. Git ignores Google's workspace
credential files. The single-user installer writes its token-bearing Nix
configuration to `/etc/nix/nix.conf`. Cachix authentication uses the runner's home
configuration directory. Both are outside `/nix`, as are the checkout, Google
credentials, Terraform data, and saved plans. Never redirect home, configuration
or temporary directories into the persisted tree.

The `build` environment must allow only the `main` branch, with no tag policy or
required approval reviewers. `tf/` declares the environment and its branch rule.
Provision them before merging the workflow that references it, since GitHub can
otherwise create an unprotected environment automatically. Set the existing
Cachix write token using `gh secret set CACHIX_AUTH_TOKEN --env build`, then remove
the repository-scoped copy after confirming the environment secret exists.
GitHub can't return the original value: obtain it from its secure source, never
from workflow logs. An environment reference alone doesn't restrict the old
repository secret. No token values belong in Terraform or Nix.

The organization manages the platform connections. Define workflow runner labels
and pinned action references here. This repository's `tf/` owns its Actions
enablement and commit pinning. `quantile-q0/q0` owns the organization allowlist
inherited by this repository. GitHub rejects a second repository-level
selected-action list. Update Q0's list when action commits change. Never add
platform-wide resources here.

Dependabot updates GitHub Actions and Terraform dependencies with conventional
commit prefixes. `update.yaml` runs scheduled review-only updates and
Dependabot auto-merge as separate, event-guarded jobs. Its
`pull_request_target` job never checks out PR code. It requests auto-merge
only for stable minor/patch updates from the Dependabot bot. Non-bot PRs show
both dependency jobs as skipped because GitHub starts the workflow for each PR.
Required checks and branch protection still gate merges. Maintain review
requirements when adding maintainers.

The dependency matrix runs `git:update-hooks`, `nix:update-nixpkgs`, and
`devenv:update-ci` from their owning Nix modules. Each matrix entry uses a
private store snapshot without commit rights, runs `check:all`, and files a separate review-only PR. No toolchain PR auto-merges. The Dependabot job calls
`dependabot:automerge` from `nix/dependabot.nix`. Both jobs check out trusted
`main`, never the PR head. Checkout drops persisted credentials before
updating inputs. Store the dedicated pull request token as
`GH_UPDATE_WORKFLOW_TOKEN` with `gh secret set`, not Terraform. GitHub reserves
the `GITHUB_` prefix for secrets and workflow environment variables. Use an
expiring fine-grained personal access token scoped only to this repository,
with Contents, Pull requests, and Workflows write permissions. Workflows
permission lets the updater change the pinned CLI in workflow files. Don't
grant organization or administration permissions. This remains a repository-scoped
secret, not an environment-scoped one. A missing token fails closed.
`GITHUB_TOKEN`-created PRs would not trigger validation. Matrix job names display
only `matrix.label`. Keep the target and task identifiers as internal settings.

Plan and Apply set `SECRETSPEC_PROFILE=prod` before Devenv runs. Devenv
resolves its required SecretSpec declarations at shell entry. Missing inputs
fail before OpenTofu initialization without a separate secrets check step. PR
validation uses the credential-free default profile with only the optional
compatibility placeholder. Leave that placeholder unset. Never interpolate
deployment values into PR jobs or commit them.

Workflow invocations pin the CI Devenv executable by revision. Keep all
workflows on the same revision when updating it. Update the nixpkgs pin and
verify the OpenTofu version when changing the toolchain. Apply must continue
using the saved plan created in its own job. Never introduce
non-manual production applies, PR cloud credentials, or the old GitLab
HTTP-backend/state-push workflow. `tf/README.md` documents the one-time
local-to-Cloud Storage migration.
