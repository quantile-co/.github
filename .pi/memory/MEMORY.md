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
- The committed flake lock pins Factory. `flake.nix` evaluates native Factory
  modules with `pkgs` and the pinned `factory.inputs`, explicitly selecting tools,
  native files and workflow concurrency. No local `nix/` or `etc/` layer is needed.
  Keep Terraform module refs aligned with the reviewed Factory contract.
- Local development and CI enter the same pinned direnv shell. Explicit shell
  hooks reconcile native files before setting checkout-local Pi memory. `.envrc`
  retains only local configuration, pre-evaluation cache trust and shell entry.
  Copies are tracked regular files; Check compares their Git-index contents too.
  Template sources are not runtime paths; Vale assets live in `.vale/`.
- Pnpm owns frozen installation and Husky prepare. Two small apps replace scripts:
  `apps/repo` owns checks/fixes/tests; `apps/github` owns protected Plan/Apply.
  Vite builds Node CLI artifacts; TypeScript checking stays separate. Turbo caches
  only reproducible `dist/**` outputs locally. Checks, fixes and tests are uncached;
  there is no remote Turbo cache. Plan/Apply use locked tsx outside Turbo and need
  no build prerequisite. Checks/fixes never install dependencies or hooks, and
  automatic pnpm installation is disabled. Each workflow installs frozen
  dependencies immediately before its pnpm task in the same run block.
- Factory Pi and saved-plan transport are exact-version public npm dependencies,
  pinned with integrity in this repository's lockfile. Pi loads the prebuilt
  package through native settings, with independently pinned Herdr integration.
  Do not copy shared extension/skill trees or require physical Pi SDK peers.
  Run `pnpm run skills:sync` explicitly after installation to select the packaged
  deployment skills and pinned Terraform style skill. Review `skills-lock.json`;
  ignored `.agents/skills/` is generated. Never sync during install, builds,
  shell entry or Pi startup. Keep QMD configuration seeded and repository-owned.
  No placeholder Build or Update workflow is needed here.
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
The GitHub app maps the Infrastructure layer internally to `tf/`.
Moving the source directory does not move state or change resource addresses.
It manages this repository and its state project, not organization-wide
infrastructure. Preserve the existing bucket and
`.github/prod/infrastructure` backend and existing lineage. Q0 owns organization
controls, runner profiles and WIF.
The production WIF boundary admits approved manual main Plan/Apply jobs in `prod`;
do not widen it for diagnostics or run Day Zero on this installation.

The repository-owned Commander app uses Factory's shared saved-plan transport.
Plan stores saved bytes and private diagnostics only in GCS; Apply uses the
operator-selected `gh_plan_ref` generation without replanning. Local review uses
`GH_PLAN_REF`; do not add aliases or arbitrary directory/backend options. Map
`GH_REPO_TOKEN` internally to provider credentials only; storage receives neither
the repository token nor ambient Terraform inputs. No GitHub artifact or receipt
is produced. Keep main fixed during review, plus main/prod guards, backend locks
and production concurrency. The required Check context is `All`; it includes
mocked CLI boundary tests. A merge does not authorize deployment. Human
plan-reader grants cover `plans/`, not state or administration.

Paired owner/member records live in `tf/main.tf` locals and project directly to
platform modules. Only the trusted WIF pool remains a Terraform runtime input.
Members receive GitHub write only, without GCP or deployment grants. The removal
of both original-actor and triggering-actor YAML roster checks is intentional;
authorization remains in repository/environment policy and existing source-defined
WIF/IAM. No Actions roster is read by the app. Any existing unmanaged roster
variable may be retired only with separate approval. See the installed shared
[configuration contract](../../node_modules/@quantile-co/factory-pi/skills/deploy/references/configuration.md).

Retain `github-49cc-tf-state`, `.github/prod/infrastructure`, platform instance keys and
existing permissions. Keep `module.gh`, `gcp_project_id`, `gh_repo_id` and
`GCP_TF_STATE_BUCKET` without fallback names or state-migration scaffolding.
The concrete billing account, parent folder and `US` bucket location are verified
installation values, not runtime overrides. Source migration is not deployment
or permission to replay an older saved plan.

## Completed deployments

- Backend cutover: protected migration `40171954208` on `f4a7412` moved
  `repository/prod` to `.github/prod/infrastructure` in the existing bucket.
  Native OpenTofu retained lineage and operational state with serial +1;
  only transient `check_results` normalization was excluded from comparison.
  Exact backups and private diagnostics stay under `state-backups/`, outside
  `plans/`. The old live state object was retired conditionally after verification.
  Temporary migration tooling was removed; normal workflows use only the new
  prefix. No resource Plan/Apply ran. Prior saved plans are not approved for reuse.


- Native workspace activation: protected Plan `40154328955` on `7bd34b0`
  confirmed no infrastructure changes. Separately approved CLI cleanup removed
  the unused, unmanaged `PROJECT_OWNERS` repository variable; no owner/member
  Actions roster remains. No Apply or state migration was needed. Existing
  project IAM and Storage audit configuration were verified unchanged. This
  completed cleanup is not authorization for another deployment or IAM cleanup.

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
