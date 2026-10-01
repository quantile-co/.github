# Repository settings and state

**README edits:** be very judicious. Ask the user and get explicit approval
before editing any README. Propose only necessary, succinct changes. Keep
workflow details and agent implementation guidance in `AGENTS.md`, not READMEs.

This single OpenTofu root manages `quantile-co/.github` settings and its
Google Cloud state project and bucket. After the one-time local-state Day 0
bootstrap in [`README.md`](README.md), state uses the Cloud Storage backend with
state bucket `TF_STATE_BUCKET` and prefix `repository/prod`. Never point it at another
repository's backend or commit credentials, state files, or saved plans.

Run `devenv tasks run check:tf` for backend-free init, format,
validation, and TFLint. Its dedicated `TF_DATA_DIR` must not load a production
backend left in `tf/.terraform`. It must not require cloud credentials. A real plan or
apply requires authorized Google Cloud and GitHub credentials and the
repository's `TF_VAR_*` inputs. Use `SECRETSPEC_PROFILE=prod` on credentialed
Devenv runs after Day 0. The profile requires its inputs before entering the
shell. Never add a second protected root or GitLab HTTP backend.

Keep repository branch protections, environment gates, workload identity
federation principal bindings, project/bucket deletion safeguards, and Cloud
Storage state versioning. The manual Plan workflow never applies. The manual
Apply workflow plans again and applies that exact saved plan in the same job
when an authorized maintainer invokes it.

The `build` environment is the replacement for `cache`. During migration, keep
both environments and their main-only policies. Switch Build only after the
replacement has its upload secret, then remove the old environment.

The separate publication environment grants access only to the `main` branch through
an explicit branch deployment policy. It doesn't grant access by tag or by
branch protection status alone.
It has no required approval reviewers. Provision the environment and rule before
Build starts referencing it. Store `CACHIX_AUTH_TOKEN` through GitHub's secrets
interface, never Terraform. After provisioning the environment secret, remove
the repository copy so other branches can't access that credential.
