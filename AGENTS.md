# Organization repository agent guide

**README edits:** be very judicious. Ask the user and get explicit approval
before editing any README. Propose only necessary, succinct changes. Keep
workflow details and agent implementation guidance in `AGENTS.md`, not READMEs.

This is the public `quantile-co/.github` repository, not the app's `.github/` directory. `profile/README.md` is the approved
public organization profile. The root `README.md` describes this repository. Preserve the profile's
approved copy and the root README's centered header and horizontal navigation.

Review `.pi/memory/MEMORY.md` for project-specific workflow, tooling, and
infrastructure history; source and current workflows take precedence. There are
no nested agent guides. Do not edit READMEs without explicit approval.

`tf/infrastructure/` consumes pinned Factory modules against this repository's
**existing** bucket and `repository/prod` backend. The historical Day 0 commands
in `tf/README.md` must not be rerun. Preserve migration moves and the provider
alias until a separately authorized production Apply and state verification.
The former `build` environment and its deployment policy are slated for deletion
by a reviewed Apply, not by an unreviewed live configuration change. Preserve
the `prod` gate, protected main, both maintainer checks, WIF, backend locking,
and production concurrency. The organization-level Cachix secret is shared;
do not create a repository-scoped replacement or pass it to PR Check.
The pinned reusable Check emits `All / All`; live main protection now requires
that same GitHub Actions check, strictly. The status cutover changed no other
protection settings. Merge this branch only through the existing protected PR
process. Never bypass protection or use a production Apply to force a merge.
A production Plan was approved, but review its private saved artifact and
state effects before considering the separately approved Apply.

`tf/` manages this repository's settings and its dedicated state infrastructure,
not organization-wide administration, app hosting, or domain name system
management. Never add private topology, credentials, or unrelated
infrastructure here.

## Development

Local prerequisites are Nix and direnv; `.envrc` selects the pinned Devenv
CLI from the flake. All repository checks run with `devenv tasks run check:all`
without cloud credentials or a remote backend. `devenv.nix` orchestrates
pinned Factory tool modules and native files. Importing a module must not
install hooks or run checks. Install Git hooks explicitly and run Git checks
at pre-push, not commit. Git ignores the optional local credential file
`.envrc.local`.

Prefix project-defined environment variables, secrets, and parameters with
their owning platform or component. Keep tool-required names such as
`GH_TOKEN` and `TF_VAR_*`. Use `GH_` for custom GitHub credentials because
GitHub reserves `GITHUB_` for its own secrets and workflow variables.

## Knowledge maintenance

Keep this guide self-contained. The parent workspace, app repo, old
backups, and research notes may move or disappear. This repo must not depend on
them. Update reviewed, repository-specific `.pi/memory/MEMORY.md` when
implementation decisions or failure modes change. Keep human READMEs short
and never change the approved public profile without explicit approval. Never
commit secrets, state, provider payloads, or saved plans.
