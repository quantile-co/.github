# Development environment

**README edits:** be very judicious. Ask the user and get explicit approval
before editing any README. Propose only necessary, succinct changes. Keep
workflow details and agent implementation guidance in `AGENTS.md`, not READMEs.

`devenv.nix` imports `nix/default.nix`, which lists domain modules in this
directory. Keep the entrypoint small and group checks with their related tools
rather than building the old superset module/scaffold system. A new domain
warrants a new file only when it adds meaningful behavior.

Declare every project tool in the devenv packages, including tools used for
maintenance and deployment. Devenv supplies its own CLI and the base shell
utilities. Keep project commands inside devenv locally and in CI/CD. Don't rely
on host tools or add separate tool installers. Stock actions still handle
checkout, Nix bootstrap, and authentication. `devenv test` checks that project
tools resolve into the Nix store.

Keep CI workflows as thin wrappers around these Nix-defined tasks. PR
validation runs `check:all`. The post-merge Build smoke-tests and publishes
trusted outputs without repeating the full gate. Neither workflow should
reimplement a check in YAML. Run `devenv tasks run check:all` for the
same local gate as validation CI.
The gate covers OpenTofu formatting, backend-free initialization and TFLint,
Markdown, YAML, actionlint for GitHub Actions, and Nix formatting and static
checks. It also runs typos, Open Policy Agent deployment and cache policies,
cache signature/key configuration checks, tested Semgrep rules,
Trivy filesystem scanning, Vale prose and AI-writing detection, Git-history
and working-tree secret scanning, and `devenv test` shell smoke tests.
`check:git` rejects shallow checkouts rather than claiming full-history coverage.
Every declared check runs
in this gate. Each domain stays in its own module. A shared file format does
not make different tools one domain. Keep these tasks usable without GitHub or
Google Cloud credentials or remote Cloud Storage access. `check:tf` uses
`-lockfile=readonly` so provider lock changes remain explicit, and sets
`TF_DATA_DIR=$DEVENV_STATE/tofu-check` so a previous production initialization
can't supply backend metadata to a credential-free check. `nix/nix.nix`
updates the whole pinned nixpkgs input. `nix/devenv.nix` updates only the CI
Devenv revision. Both file review-only proposals and must pass `check:all`.
Review the resulting tool versions before merging.

`nix/cache.nix` configures public Cachix pulls and checks signature enforcement
and the expected Cachix/NixOS CI keys. Signed remote readback commissioning is
complete. Don't restore its custom probes or signature fixtures.
`cache:roots` selects this job's devenv GC roots and the pinned Cachix binary
for the stock action's `pathsToPush`. Explicit roots include restored paths.
A before/after store scan would miss them. Build smoke-tests once, then publishes
those closures without repeating `check:all`.
Only Build's remote publisher receives Cachix upload credentials, through the
main-only `cache` environment. No Nix module stores them. Namespace mounts the
active `/nix` store and database before a standard single-user installation.
Its profile permits snapshot commits only from protected main, including Plan
and Apply. The input-update matrix adds no-commit because it evaluates unreviewed
versions. Other jobs rely on the profile's branch policy, not a blanket PR ban.
`cache:sync` flushes the filesystem after successful work. Namespace handles the
snapshot lifecycle. Signed remote substitutions remain the fallback on misses.
Keep credentials and temporary files outside `/nix`. Cache tags alone aren't
authorization.
Entering the local shell installs a pre-push Git hook that runs `check:all`.
Unlike the old shared module framework, it never scaffolds tracked files.
`.editorconfig` guides editors. Domain formatters and CI checks enforce
source formats. New checks should pass against approved content. Never rewrite
`profile/README.md` merely to satisfy a new lint rule. Declare any network or
credential prerequisite, and keep it outside the credential-free `check:all`
gate. Local Open Policy Agent rules inspect workflow source, not effective
GitHub permissions or a cloud plan. The Semgrep rule catches missing or unsafe
bucket public-access prevention. It doesn't evaluate live identity and access
management permissions. Trivy ignores three documented exceptions in
`.trivyignore`: intentional public visibility, separate vulnerability alerts,
and the current unsigned-commit policy.

Vale uses the pinned Google package in `.vale/styles/Google/` and a small
`Quantile` style for rule-based AI-writing detection. Every enabled Vale finding
has error severity and fails `check:vale`. The check tests all eight local
AI-writing rules, two promoted Google advisories, and a clean fixture in
`.vale/test/`. A pattern match is a detection signal, not proof of authorship. The first-party YAML and typos
checks skip vendored Google rules but cover newly added repository content.
Workflow-specific Open Policy Agent rules and tests sit next to their workflow
YAML in `.github/workflows/`. Local Semgrep rules and tests live in
`.semgrep/`. Keep policy tests alongside each rule. These checks can't prove
that the deployed environment is secure.

The `default` SecretSpec profile requires no credentials for local/CI checks.
`SECRETSPEC_PROFILE=prod` selects required inputs automatically during
Devenv evaluation. `nix/secrets.nix` forces validation without mapping values
to Nix `env`. The old mapping wrote a synthetic token into a world-readable
Nix store file. With the env provider, required inputs already pass through to
the child shell. Never select the prod profile in untrusted PR validation or
commit actual values.
