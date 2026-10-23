# Organization repository memory

Current source, tests and deployment skills take precedence.

## Memory policy

Keep durable repository decisions, unresolved issues and deployment outcomes.
Exclude machine-specific details, temporary paths, session handoffs, routine
validation results and investigation transcripts. Commit sanitized notes with
related changes, without recurring note-only validation cycles. Never retain
credentials, provider payloads, state or saved plans.

## Consumer conventions

- Consume Factory's modules, tools, native policies and workflow templates as-is;
  do not recreate the obsolete downstream architecture or policy framework.
- The committed flake lock pins Factory. `flake.nix` declares public packages,
  development tools, copied native files and small repository-specific workflow
  substitutions through Factory's `lib.mkFlake`; no local `nix/` module layer is
  needed. Keep Terraform module refs aligned with the reviewed Factory contract.
- Local development and CI enter the same pinned direnv shell. `.envrc` runs
  `factory-files write`; selected copies are tracked regular files. Check also
  compares their Git-index contents. Template sources are not runtime paths;
  Vale assets live in `.vale/` (`StylesPath = .vale`).
- Pnpm owns prepare/check/fix/test entry points under `scripts/pnpm/`, with
  matching workflow wrappers under `scripts/github/`. Checks are read-only;
  fixes and Husky installation are explicit. Required tools come from pinned
  inputs, not undeclared installations.
- Dependabot's native configuration is a tracked copy selected from Factory.
  Check validates committed/indexed configuration; update the flake lock and
  respect module provider constraints rather than weakening bot checks.
- Keep `AGENTS.md` a navigation index and use shared deployment skills.
  README changes, including the approved organization profile, need approval.
  Root README is seeded once and then repository-owned; `profile/README.md` stays
  static. Gitignore, direnv and Husky pre-push are explicit Factory copies.

## Repository and deployment policy

PRs are optional; writers may fast-forward main after exact-head required checks.
Optional PR merges are squash-only. Retain signed commits, linear history,
strict `All`, admin enforcement and no force pushes/deletions. Do not
restore legacy required-review or maintainer-only push restrictions, auto-merge,
merge queues or the removed member-landing ruleset.

Check is credential-free and backend-free. Credentialed workflows enter the
same direnv shell and supply provider credentials only at runtime. Forward
named secrets explicitly, never `secrets: inherit`; never resolve credentials
into Nix values. Preserve cache signatures and main-only publication.

`tf/` is the single Terraform root; there are no local Terraform modules.
Workflow wrappers select `TF_DIR=tf`; workflow labels can remain Infrastructure.
Moving the source directory does not move state or change resource addresses.
It manages this repository and its state project, not organization-wide
infrastructure. Preserve the existing bucket and
`repository/prod` lineage. Q0 owns organization controls, runner profiles and WIF.
The production WIF boundary admits approved manual main Plan/Apply jobs in `prod`;
do not widen it for diagnostics or run Day Zero on this installation.

Native Plan calls OpenTofu directly and stores saved bytes and optional private
diagnostics only in GCS. Apply downloads the operator-selected `plan_ref`
generation and applies those
exact bytes without replanning; no GitHub artifact or receipt is produced. Keep
main fixed during review, plus environment/actor guards, backend locks and
production concurrency. The native required Check context is `All`. A merge does not authorize deployment.
Human plan-reader grants cover `plans/`, not state or administration.

The root directly projects required paired `project_owners` into platform owner
inputs; `project_members` defaults to empty and grants GitHub write only. Confirm
pairings before publishing `PROJECT_OWNERS`; never infer them from legacy lists.
Both workflow actors must be owners. See the shared
[configuration contract](../skills/deploy/references/configuration.md).

The deployed configuration retains `github-49cc-tf-state`, `repository/prod`,
platform instance keys and existing permissions. The root uses `module.gh`,
`gcp_project_id` and `gh_repo_id`, with `PROJECT_OWNERS` and
`GCP_TF_STATE_BUCKET`; optional `PROJECT_MEMBERS` defaults to `[]`.
Retire legacy maintainer, billing/folder and `TF_STATE_BUCKET` variables only
after callers stop using them and with separate approval.
The concrete billing account, parent folder and `US` bucket location are verified
installation values, not runtime overrides. Source migration is not deployment
or permission to replay an older saved plan.

## Completed deployments

- Configuration contract rollout: approved Apply `39923367928` succeeded on
  frozen main. The `module.github` → `module.gh` address migration completed;
  its temporary root moved block was removed afterward. This does not authorize
  another deployment or manual deletion of legacy variables.

- Factory adoption: Plan `39317595580`, receipt `12217849725`, approved Apply
  `39319984039`. Eleven address moves retained identities; retiring old build
  environments and review/push restrictions was intentional. Temporary handoff,
  recovery tooling, moves and provider alias were removed. Ordinary Plan
  `39321902718` and Apply `39322317684` established clean provider/state convergence.
- Storage audit rollout: Plan `39373967681`, receipt `12242885657`, approved Apply
  `39374670110`. ADMIN_READ, DATA_READ and DATA_WRITE were verified without
  exemptions. Existing backend and managed resources were preserved.

These outcomes are closed, not approval to replay an artifact or repeat a migration.
