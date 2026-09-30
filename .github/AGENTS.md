# Repository workflow configuration

`check.yaml` runs credential-free `check:all` once on PRs. Protected main
requires its `All` status. Check and the review-only updater fetch full Git
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

Validation, deployment, and Dependabot maintenance use Namespace runners
with fresh Nix installations. Don't restore `/nix` or delete installer
receipts. Namespace cache tags aren't authorization: editable workflow labels
can request another tag. Persistent runner-store reuse remains deferred until
the audit verifies server-enforced access controls and the installer/credential
lifecycle. Don't reuse existing volumes as trusted stores. Binary cache
reads still provide reuse, with `require-sigs = true`. Configure Cachix reads
through additive `extra-substituters` and `extra-trusted-public-keys` settings
in the installer. The Cachix action's configuration step replaces the
effective key list and removes FlakeHub's keys. The publisher must keep
`skipAddingSubstituter: true`. PR checks verify that both sets of keys remain.

After a checked PR merges, only Build's guarded main publisher runs the
Cachix and FlakeHub upload actions. Supply the per-cache Cachix write token
as the GitHub Actions secret `CACHIX_AUTH_TOKEN`, only in the publisher job.
The Cachix action scans this fresh store at job end instead of installing a
second live upload hook. PR checks have neither cloud identity nor cache
write credentials. Shared setup, readback, Plan, Apply, and dependency jobs
must not run upload actions. Never place production credentials in store paths.
Checkout doesn't persist its Git credential. Git ignores Google auth's
workspace credential files.

The commissioning readback job downloads a run-specific, reference-free,
input-addressed probe from each actual HTTPS cache into independent empty
stores. It requires signatures from the expected cache keys and checks the
publisher's Nix archive hash. Never use fallback substituters or signature
bypasses. The Magic Nix Cache loopback service isn't a FlakeHub read endpoint.
Remove the probes and readback job once readback proves both caches, not
Nix's signature verification or the lightweight workflow policies.

Determinate automatically logs into FlakeHub when GitHub provides OpenID
Connect credentials. Publisher and readback need them for FlakeHub. Plan and
Apply need them for Google Cloud and also trigger this login. Not installing an uploader prevents
automatic publication, but doesn't establish a server-enforced read-only
FlakeHub identity. Don't claim that narrower authorization without verifying
FlakeHub's policy. Credentials remain on disposable runners, not cached volumes.
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
fresh runner store, runs `check:all`, and files a separate review-only PR. No toolchain PR auto-merges. The Dependabot job calls
`dependabot:automerge` from `nix/dependabot.nix`. Both jobs check out trusted
`main`, never the PR head. Checkout drops persisted credentials before
updating inputs. Store the dedicated pull request token as
`GH_DEPENDENCY_PR_TOKEN` with `gh secret set`, not Terraform. GitHub reserves
the `GITHUB_` prefix for secrets and workflow environment variables. The workflow
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
