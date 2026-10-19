# Project memory

Read root `AGENTS.md` first. Source, current workflows and tests take precedence
over historical notes. Never commit credentials, provider payloads, state, saved
plans, backend overrides or raw transcripts. Review and commit sanitized memory
with source changes; keep private recovery evidence outside Git.

## Factory consumer

#decision [[org-factory-consumer]] [[org-tool-policy]]
This repository consumes Factory's Terraform modules, Nix tools, native policies,
Pi skills and reusable Check/Test/Plan/Apply workflows. Use the upstream behavior
as-is rather than preserving the old downstream architecture. The shared pin is
`92ef45786d2f003559ffc9d41f56bc7a8763c7d9`; update the flake/Devenv pins and locks,
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
published and synced before this final pin alignment. All consumer references
and both locks now select that SHA; local backend-free check:all and test:all
passed again. No Terraform module content or provider-lock changes and no
production Plan/Apply.

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
