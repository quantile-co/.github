# Repository settings and state

This single OpenTofu root manages `quantile-co/.github` settings and its
Google Cloud state project and bucket. After the one-time local-state Day 0
bootstrap in [`README.md`](README.md), state uses the Cloud Storage backend with
deployment bucket
`TF_STATE_BUCKET` and prefix `repository/prod`. Never point it at another
repository's backend or commit credentials, state files, or saved plans.

Run `devenv tasks run check:tf` for backend-free init, format,
validation, and TFLint. It must not require cloud credentials. A real plan or
apply requires authorized Google Cloud and GitHub credentials and the
repository's `TF_VAR_*` inputs. Use `SECRETSPEC_PROFILE=deploy` on credentialed
Devenv runs after Day 0. The profile requires its inputs before entering the
shell. Never add a second protected root or GitLab HTTP backend.

Keep repository branch protections, environment gates, workload identity
federation principal bindings, project/bucket deletion safeguards, and Cloud
Storage state versioning. The manual
GitHub deploy workflow is plan-only by default and applies only the exact plan
produced in its own run when an authorized maintainer explicitly requests it.
