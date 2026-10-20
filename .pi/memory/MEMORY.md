# Project memory

Read root `AGENTS.md` first. Source, current workflows and tests take precedence
over historical notes. Never commit credentials, provider payloads, state, saved
plans, backend overrides or raw transcripts. Review and commit sanitized memory
with source changes; keep private recovery evidence outside Git.

## Factory consumer

#decision [[declared-runtime-dependencies]]
All required commands and native runtime dependencies must come from pinned
Devenv/Nix inputs or locked language packages, not host installations or global
packages. This applies to local and workflow tasks, including deployment tools.
Restricted-PATH and isolated-cache validation must expose undeclared tools;
a successful run with the developer's usual environment is insufficient.
Nix/direnv bootstrap prerequisites remain explicit.

#decision [[org-factory-consumer]] [[org-tool-policy]]
This repository consumes Factory's Terraform modules, Nix tools, native policies,
Pi skills and reusable Check/Test/Plan/Apply workflows. Use the upstream behavior
as-is rather than preserving the old downstream architecture. The shared pin is
`67a955ddf9ad0a9a2fd335d7486b28d9f78a0243`; update the flake/Devenv pins and locks,
Terraform module sources and workflow callers together when appropriate.
`devenv.nix` owns local task orchestration and native config links. Imports do not
install hooks or run checks. Hook installation is explicit and shared across Git
worktrees; checks run at pre-push, not commit. Fixes are explicit, checks read-only.

Dependabot is a tracked copy selected from Factory's native policy for GitHub
Actions, OpenTofu and Nix. Check compares the Git index to the selected policy.
Nix updates must synchronize `flake.lock` and `devenv.lock`. Provider updates must
respect the pinned module's constraints. Do not weaken Check to merge bot PRs.
Keep checks/tests small and behavior-focused; avoid redundant validation and
new downstream policy frameworks.

#decision [[org-local-cache]]
The consuming `devenv.nix` explicitly pulls the public `quantile-co`, `cachix`,
`pre-commit-hooks`, and `go-overlay` caches; Devenv already adds `devenv`.
No local push/token requirement, Nix evaluation-time secret resolution, or
shared Factory module was added. `cachix.pull` applies to Devenv-managed
operations, not the `.envrc` Nix CLI bootstrap, and untrusted multi-user daemon
settings can ignore requested substituters/keys; host-level cache setup remains
operator-owned. CI also reads Numtide: its `cache.numtide.com` URL and public
key are configured in the consuming `.envrc` through `NIX_CONFIG` after the
CLI bootstrap and before `use devenv`, not as a fake Devenv Cachix-name entry.
Direct Devenv invocation without direnv does not inherit that setting.

#implementation #verification [[org-shared-checks]]
The user approved replacing embedded check logic with Factory-owned commands.
Dependabot's checker verifies the selected policy against the Git index;
check-devenv-locks --ci owns working-copy and CI-index validation. OpenTofu's
nonempty checker selects tracked source, and its backend-free checker runs
TFLint as a companion with the same isolated module data. No downstream hash or
DEVENV_STATE layout knowledge remains. Task order, roots and native selections
stay consumer-owned. Factory source 78fcee2 passed Check 39329979854 and landed
normally before adoption. The flake/Devenv pins and locks, all four workflow
callers and both Terraform module references were updated together; Terraform
module contents and provider locks are unchanged. Local backend-free check:all
and test:all passed. This also adopts shared nonempty SecretSpec validation and
the 10-minute Check/Test, 20-minute Plan/Apply budgets. No production workflow
was run for this change.

#preference #verification [[org-factory-consumer]]
The consumer must pin the latest reviewed Factory main after upstream source
and outcome commits are finished, including documentation-only commits, rather
than intentionally retaining an earlier implementation-only SHA. Initial
adoption c569f21 passed Check 39330886727 and landed normally. Final Factory
main 92ef45786d2f003559ffc9d41f56bc7a8763c7d9 passed Check 39331840904 and was
published and synced before that pin alignment. At the time, consumer references
and both locks selected that SHA; local backend-free check:all and test:all
passed. No Terraform module content or provider-lock changes and no
production Plan/Apply.

#verification #decision [[org-local-cache]] [[org-factory-consumer]]
The signed organization local-read cache commit e83638f passed exact-head
Check 39340785130. Factory's corresponding cache commit 1fba32e passed
Check 39340693542 and fast-forwarded its protected main. Its C follow-up
16ca0ee passed Check 39340723225; the outcome-note descendant 0b291a5
passed Check 39341304861 and fast-forwarded Factory main. The separately
authorized main Test 39341977302 passed at 0b291a5. Factory's signed,
documentation-only result note c0fd548 records that Test outcome. This
repository aligns its flake/Devenv pins and locks, all four workflow
callers, and both Terraform module sources to that final Factory SHA. No Terraform module
content, provider locks, backend, or production authorization changed.
The final consumer alignment d87dbf7676abd2fdc2edc266a512dd2b678e5bbe
passed exact-head Check 39342887708 and was ordinarily fast-forwarded to
protected main. Local `nix flake check path:.`, backend-free Terraform
format/init/validate and Devenv `test:all` passed on that same source. No
production Plan or Apply ran. Subsequent historical module review is
read-only, with no further rollout implied.

#decision #implementation #verification [[org-factory-consumer]] [[factory-semgrep-pinning]]
The reviewed July Factory source 99acec8 passed exact-head Check 39371988636,
fast-forwarded its protected main, and passed separately requested main Test
39372264980. The organization consumer's coordinated Factory pin update selects
that SHA in its flake/Devenv inputs and locks, all four reusable workflow callers
and both Terraform module refs. Its native Dependabot copy gains seven-day
version-update cooldowns. The Semgrep consumer explicitly adds the pinned
`owasp-top-ten`, `secrets`, `security-audit`, and `terraform` packs beside its
local rules; Go, JavaScript, Python, Docker and Kubernetes packs are not selected
for this repo's Nix/Terraform/workflow/prose source. New Factory OpenTofu and
TFLint check packages are invoked independently with the same root; fixes fail
on the first error. Local backend-free check:all, test:all and OpenTofu
format/init/validate passed on the candidate branch. The new GCP module also
declares authoritative Cloud Storage service audit logging; this is not active
merely by pinning or testing source. Review existing service-specific audit
settings and inherited exemptions as well as the private saved Plan before
any separately approved Apply. Preserve production guards, receipt-only public
artifacts and original state backend. No production run is implied by this note.

#verification #deployment [[org-factory-consumer]] [[factory-storage-audit]]
The signed source alignment 87abdc9 passed exact-head Check 39373002009
(`All / All`), ordinarily fast-forwarded protected main, and passed manual main
Test 39373217932. (An unsigned candidate was rejected by protected main;
identical source was recommitted with a verified SSH signature on a new branch,
without force-pushing or deleting the original branch.) Authorized Plan
39373967681 returned receipt artifact 12242885657; privately verified saved
bytes showed only one new authoritative Cloud Storage audit config with
ADMIN_READ, DATA_READ and DATA_WRITE, zero exemptions, no updates or deletions.
Read-only project, folder and organization policies had no existing
service-specific/allServices audit config or inherited exemption. Following
separate approval for that exact artifact, protected Apply 39374670110
succeeded; a fresh project IAM policy read confirmed all three log types and
zero exemptions. The backend prefix and prior module-managed resources were
preserved. Factory's outcome-only follow-up 0764e6f passed Check 39375060149
and fast-forwarded main; all flake/Devenv, workflow and Terraform module pins
are aligned to that latest reviewed commit without changing executable code.
Local backend-free test:all passed for the documentation-only pin using
process-local two-CPU affinity and Git HTTP/1.1 after transient GitHub clone
resets and a host-specific Semgrep io_uring allocation error; no checker was
disabled or policy weakened. No raw plan, IAM policy, provider values or state
were stored in Git.

#implementation #verification [[org-factory-consumer]]
Factory's fetched-skill/Git-aware secret-scan implementation b90ad44 passed Check
39383602750; its outcome head 5a7f9bf passed Check 39383963111 and both landed
normally on protected main. This consumer aligns both inputs/locks, all workflow
callers and Terraform module refs to that final SHA. Hook installation is
explicitly named `install:git:hooks`. Local backend-free `test:all` (including
Check) passed. Terraform module contents, provider locks and backend are
unchanged; no production workflow was dispatched. Fetched optional skills remain
consumer-selected, not implicitly activated. Signed adoption
`16f111342b1318e9f42f3ee3229105fbafd8e887` passed exact-head Check `39384866409`
(`All / All`) and fast-forwarded protected main through normal pre-push checks.
No manual Test, Plan or Apply was dispatched for this source-only adoption.

#verification [[declared-runtime-dependencies]]
The consumer explicitly selects pinned Nix, Git, Bash, Coreutils and Diffutils.
The `.envrc` bootstrap enables flakes without depending on a user's Nix config.
Local backend-free `test:all` passed with only Nix-store PATH entries and isolated
HOME/XDG caches, then passed again in a fresh detached worktree without existing
Terraform module/provider caches. No remote-state read, production workflow or
provider-backed test ran. Factory's native-tool implementation `973b7c1` and
outcome `310430e` passed exact-head Checks `39391893587` and `39392233804` and
landed normally. Terraform module contents and provider locks are unchanged.
Final Factory outcome `385fda4` passed Check `39397901879` and landed; every
consumer pin selects it. Signed adoption `cf98430` passed exact-head Check
`39398374207` and normally fast-forwarded protected main. Its final local
backend-free `test:all` passed. No production workflow was dispatched.

#implementation [[devenv-task-discovery]]
Select Factory's generic `devenv-tasks` skill through an explicit generated
project link. It discovers task descriptions, implementations and dependencies
from the current Devenv project without assuming task names or running them.
All inputs/locks, workflow callers and Terraform sources align to the reviewed
upstream publication. No Terraform module content or provider lock changed.
Backend-free local Check/Test and task listing passed; the shared skill link was
verified. Signed adoption `8959ae21d74e07648e2a7e64e273c9c68001bca3` passed
exact-head Check `39468749480` and normally fast-forwarded main. No production
workflow or remote state operation was dispatched for this adoption.

## Repository and workflow policy

#decision [[org-member-landing]] [[org-workflows]]
PRs are optional. Repository writers push a candidate branch, wait for required
Check on the exact commit, then fast-forward main normally. Optional PR merges
are squash-only. No required PR reviews, maintainer-only push restriction,
member-landing ruleset, auto-merge or merge queue. Preserve signed commits,
linear history, strict `All / All` checks, admin enforcement, and no force pushes
or branch deletions. This is the explicit October 5 and October 19 architecture
decision, not an accidental weakening to repair. Workflow-run approval for
external contributors is separate from PR code review.

Check receives no secrets and initializes OpenTofu without a backend. Test,
Plan and Apply delegate to Factory; credentialed jobs use protected main/prod,
maintainer/triggering-actor guards and WIF. Plan/Apply share production
concurrency and backend locks. Explicitly forward `GH_REPO_TOKEN` and the shared
organization Cachix token; never use `secrets: inherit`. The called workflows
enter the selected SecretSpec shell, whose shared Factory loader rejects all
empty required exports using native SecretSpec requiredness reports.
SecretSpec's env provider alone accepts present-but-empty values. Cache publishing is
main-only; keep signature verification and credentials outside persisted stores.

## Infrastructure and deployment

#decision [[org-production-guards]] [[org-infrastructure]]
`tf/infrastructure/` manages this repository and its dedicated state project,
not organization-wide resources. It imports Factory's GitHub and GCP modules.
Keep the existing state bucket and `repository/prod` backend prefix; do not
rebootstrap this installation. Q0 owns organization controls, Namespace profiles
and WIF. This repository's WIF provider accepts only manual main `plan.yaml` and
`apply.yaml` jobs using `prod`; do not widen it for diagnostics.

Plan saves private GCS bytes and publishes only a receipt. Read the exact saved
plan privately before applying its artifact ID through the existing Apply caller.
Apply does not replan. Preserve revision, expiry, digest and backend checks.
`GCP_MAINTAINERS` is a JSON array of Google account emails, distinct from GitHub
maintainers; the module grants object reads only under `plans/`, not state or
lock access. Normal private GCS plan retrieval has been verified. `prod` is the
only deployment environment. Runtime provider credentials never belong in Nix
values, Terraform inputs, source or state.

## Migration outcome

#verification [[org-factory-migration]]
The first migration Plan timed out with empty provider credentials; explicit
caller secret forwarding fixed that. Its abandoned lock was privately inspected
and removed only after user approval, exact identity verification and conditional
GCS generation/metageneration matching. Plan 39317595580 produced receipt
12217849725 at main `51d78fcb0b1464da930aae2b77d76c5d4a25ee97`. The complete saved
plan was privately reviewed: 11 address moves, no replacements, three creates,
four updates and two intentional legacy build-environment deletions. Removal of
old PR-review and maintainer push restrictions was explicitly intended.
Authorized Apply 39319984039 succeeded. Live API reads confirmed the target main
policy and only `prod`; normal Google-user retrieval matched the reviewed saved
plan bytes. No manual IAM grant or WIF relaxation was used. Temporary recovery
jobs/scripts, encryption recipient/tools, moved blocks and provider alias were
removed in signed cleanup 6e333d2d6fb4469310a68d96986ff5c08bc59bee. Exact-head Check
39321472606 passed, then an ordinary direct push landed that commit on main.
The unmodified upstream Plan 39321902718 succeeded; receipt 12220696806 was
downloaded directly from private GCS and digest-verified. Its full rendering
reported no changes, and the refreshed state contained only module-managed
addresses with no legacy GitHub provider alias. Apply 39322317684 successfully
applied those exact no-op bytes, completing state/provider convergence. The
migration and temporary-source cleanup are complete. The assistant's earlier
recommendation to restore legacy review/push restrictions was incorrect and
is withdrawn.

## Documentation

#decision [[org-readmes]]
`profile/README.md` is approved public copy. Do not change it or other READMEs
without approval. Keep root `AGENTS.md` a navigation index with no nested guides.
The shared deploy and Day Zero skills are authoritative; Day Zero is only for
new installations. Do not recreate an old downstream runbook or fork Factory's
native style/security configuration.
