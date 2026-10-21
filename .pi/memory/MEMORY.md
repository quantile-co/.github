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
- Pin Factory in the local flake; Devenv follows `this/*` and imports the
  local `nix/default.nix` module through `inputs.this.nixModules.default`. Coordinate both locks,
  materialized workflows and Terraform module pins.
  During a coordinated update, select the final reviewed upstream revision,
  including its outcome commit. Source declares the current pin.
- `devenv.nix` owns package/configuration selection and task orchestration.
  Checks are read-only; fixes and shared Git-hook installation are explicit.
  Required tools come from pinned inputs, not undeclared installations.
- Dependabot's native configuration is a tracked copy selected from Factory.
  Check validates committed/indexed configuration; synchronize both Nix locks
  and respect module provider constraints rather than weakening bot checks.
- Keep `AGENTS.md` a navigation index and use shared deployment skills.
  README changes, including the approved organization profile, need approval.

## Repository and deployment policy

PRs are optional; writers may fast-forward main after exact-head required checks.
Optional PR merges are squash-only. Retain signed commits, linear history,
strict `All`, admin enforcement and no force pushes/deletions. Do not
restore legacy required-review or maintainer-only push restrictions, auto-merge,
merge queues or the removed member-landing ruleset.

Check is credential-free and backend-free. Credentialed workflows enter the
selected runtime SecretSpec shell and reject empty required values. Forward
named secrets explicitly, never `secrets: inherit`; never resolve credentials
into Nix values. Preserve cache signatures and main-only publication.

`tf/infrastructure/` manages this repository and its state project, not
organization-wide infrastructure. Preserve the existing bucket and
`repository/prod` lineage. Q0 owns organization controls, runner profiles and WIF.
The production WIF boundary admits approved manual main Plan/Apply jobs in `prod`;
do not widen it for diagnostics or run Day Zero on this installation.

Native Plan stores saved bytes and optional private diagnostics only in GCS.
Apply downloads the operator-selected `plan_ref` generation and applies those
exact bytes without replanning; no GitHub artifact or receipt is produced. Keep
main fixed during review, plus environment/actor guards, backend locks and
production concurrency. The native required Check context is `All`. A merge does not authorize deployment.
Human plan-reader grants cover `plans/`, not state or administration.

## Completed deployments

- Factory adoption: Plan `39317595580`, receipt `12217849725`, approved Apply
  `39319984039`. Eleven address moves retained identities; retiring old build
  environments and review/push restrictions was intentional. Temporary handoff,
  recovery tooling, moves and provider alias were removed. Ordinary Plan
  `39321902718` and Apply `39322317684` established clean provider/state convergence.
- Storage audit rollout: Plan `39373967681`, receipt `12242885657`, approved Apply
  `39374670110`. ADMIN_READ, DATA_READ and DATA_WRITE were verified without
  exemptions. Existing backend and managed resources were preserved.

These outcomes are closed, not approval to replay an artifact or repeat a migration.
