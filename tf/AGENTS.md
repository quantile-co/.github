# Repository settings and state

**README edits:** be very judicious. Ask the user and get explicit approval
before editing any README. Propose only necessary, succinct changes. Keep
workflow details and agent implementation guidance in `AGENTS.md`, not READMEs.

This single OpenTofu root consumes immutable-revision Factory project modules for
`quantile-co/.github` settings and its **existing** Google Cloud state project and
bucket. The Cloud Storage backend still uses `TF_STATE_BUCKET` and prefix
`repository/prod`. `moved.tf` maps the old root resources into the Factory
modules without creating replacement infrastructure. The GitHub provider alias
preserves the existing state provider address. Both are temporary migration
scaffolding. Review a Plan from the existing remote state before separately
authorizing any Apply. After Apply, verify resource addresses and provider
bindings before removing that scaffolding in a later guarded change. The old
one-time local-state Day 0 runbook in [`README.md`](README.md) is historical
and must not be rerun against this installation. Never point this
root at another repository's backend or commit credentials, state, or saved plans.

Run `devenv tasks run check:tf` for backend-free init, format,
validation, and TFLint. Its dedicated `TF_DATA_DIR` must not load a production
backend left in `tf/.terraform`. It must not require cloud credentials. A real plan or
apply requires authorized Google Cloud and GitHub credentials and the
repository's `TF_VAR_*` inputs. Use `SECRETSPEC_PROFILE=prod` on credentialed
Devenv runs after Day 0. The profile requires its inputs before entering the
shell. Never add a second protected root or GitLab HTTP backend.

Keep repository branch protections, environment gates, workload identity
federation principal bindings, project/bucket deletion safeguards, and Cloud
Storage state versioning. The manual Plan workflow never applies. The manual Apply workflow plans again
and applies that exact saved plan in the same job when an authorized maintainer
invokes it. The root passes existing project, folder, and repository identifiers
to Factory without creating another project. `module.gcp.maintainers` is empty
because this repo doesn't distribute saved plans across workflows. Factory's
signed, linear main policy intentionally replaces this repo's older merge/review
policy. Factory also owns external-fork workflow approval through the GitHub API.
Plan/Apply supply the same repository-scoped token as `GITHUB_TOKEN` and
`REST_API_BEARER` at runtime, not as a Terraform variable. Keep the existing
`prod` and `build` environments and their main-only deployment gates. The
`build` environment holds the Cachix write secret. Migrate the environments
through the state moves rather than deleting them before reviewing the
protected workflows and token boundary.

The separate `build` publication environment grants access only to the `main`
branch through
an explicit branch deployment policy. It doesn't grant access by tag or by
branch protection status alone.
It has no required approval reviewers. Provision the environment and rule before
Build starts referencing it. Store `CACHIX_AUTH_TOKEN` through GitHub's secrets
interface, never Terraform. After provisioning the environment secret, remove
the repository copy so other branches can't access that credential.
