# Repository workflow configuration

`validate.yml` runs credential-free checks on PRs and `main`. The manual
`deploy.yml` workflow restricts deployment to trusted maintainers on protected
`main`. Deploy plans by default. An authorized maintainer can opt into applying
the saved plan from the same run. The `prod` environment gate runs before the
job. No second approval pause occurs between plan and apply. Preserve
concurrency and state locking, Google Cloud workload identity federation, and
the GitHub token boundary. Never weaken branch protection or authorizations
merely to allow a push.

Validation, deployment, and Dependabot maintenance use Namespace runners.
The separate Namespace cache tags for checks and deploy form a trust boundary.
Untrusted PR code must never write to the privileged deployment cache. The
Namespace `nix` cache action mounts the persistent `/nix` store before
Determinate Nix installs. Only the deploy job uses the FlakeHub Cache action
and needs `id-token: write`. Validation retains only `contents: read`.
The organization manages the platform connections. Define workflow runner
labels and pinned action references here. Never invent Terraform resources
for platform-wide account setup in this repo.

Dependabot updates GitHub Actions and Terraform dependencies with conventional
commit prefixes. Its separate `pull_request_target` workflow never checks out
PR code. It requests auto-merge only for stable minor/patch updates from the
Dependabot bot. Required status checks and branch protection still gate merges.
Maintain review requirements when adding maintainers. Dependabot never updates `devenv.lock` or CI's pinned Devenv revision.

The deploy job sets `SECRETSPEC_PROFILE=deploy` before Devenv runs. Devenv
resolves its required SecretSpec declarations at shell entry. Missing inputs
fail before OpenTofu initialization without a separate secrets check step. PR
validation uses the credential-free default profile. Never interpolate
deployment values into PR jobs or commit them.

Workflow invocations pin the CI Devenv executable by revision. Keep both
workflows on the same revision when updating it. Update the nixpkgs pin and
verify the OpenTofu version when changing the toolchain. The deploy workflow
must continue using the saved plan created in its own run. Never introduce
non-manual production applies, PR cloud credentials, or the old GitLab
HTTP-backend/state-push workflow. `tf/README.md` documents the one-time
local-to-Cloud Storage migration.
