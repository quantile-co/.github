# Repository workflow configuration

**README edits:** be very judicious. Ask the user and get explicit approval
before editing any README. Propose only necessary, succinct changes. Keep
workflow details and agent implementation guidance in `AGENTS.md`, not READMEs.

Use these shared verb–noun names:

- Check → All
- Build → Nix caches
- Plan/Apply → Infrastructure
- Update → GitHub Actions and OpenTofu providers

Keep the protected job IDs unchanged.
`namespace-profile-quantile` is the shared Restricted runner profile. Its cache
volume must set `allow_commit_from_branch: ["main"]`, with default profile and
repository isolation. The creation command is in the
[Q0 Day 0 runbook](https://github.com/quantile-q0/q0#day-0-runbook). This repository
consumes the profile, not its management credentials. Configure the profile
before these workflows run.

`check.yaml` has exactly one job, All, which runs credential-free `check:all`
once on PRs. Don't add tool-specific Check jobs or an aggregate gate. Protected
main requires its `All` status. Check fetches full Git history for Gitleaks.
The secret-scanning task rejects shallow checkouts.
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
Namespace manages snapshot completion without a custom flush task. Treat
snapshots as optional. Signed remote substitution handles missing store paths.

Keep `require-sigs = true`. Follow Ghostty's stock integration order: mount
`/nix`, install Nix, configure `cachix/cachix-action`, then run project commands.
The Cachix action configures public reads and signing keys. All readers set
`skipPush: true`. Only Build's guarded `publish-caches` job receives
`CACHIX_AUTH_TOKEN`. Use `useDaemon: false`, as Ghostty does. The action uploads
the before/after store difference after the job, including dependencies of those
paths. Paths already in the restored store aren't selected independently.
Don't add explicit-root selection, a custom Cachix executable, or a flush
task. Build smoke-tests once without repeating the full gate.

Only Build publishes to remote Cachix. Namespace snapshot commits are separate.
PR checks have no cloud identity or remote cache write credentials. Only Plan and
Apply request OpenID Connect for Google Cloud. This repository no longer uses Determinate or FlakeHub.
Keep commissioning probes, the readback job, and custom signature fixtures out
of routine CI. Retain signature enforcement and lightweight workflow policy tests. Never place production credentials in store paths.
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
commit prefixes. `update.yaml` has only a `pull_request_target` Dependabot
auto-merge job. It checks out trusted `main`, never PR code, and calls
`dependabot:automerge` from `nix/dependabot.nix` using the job-scoped
`GITHUB_TOKEN`. It requests auto-merge only for stable minor/patch updates
from the Dependabot bot. Non-bot PRs show this job as skipped. Required checks
and branch protection still gate merges. Maintain review requirements when
adding maintainers.

There is no scheduled or manual input-update workflow or dedicated updater
token. Update the pinned git-hooks and nixpkgs inputs in `devenv.yaml`
and `devenv.lock`, and the Devenv CLI commit in workflows, by a separately
reviewed manual change. The local `git:update-hooks`, `nix:update-nixpkgs`,
and `devenv:update-ci` tasks remain available for that purpose. Run the full
`check:all` gate before filing a PR. GitHub reserves the `GITHUB_` prefix for
secrets and workflow environment variables.

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
