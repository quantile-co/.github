# Development environment

`devenv.nix` imports `nix/default.nix`, which lists domain modules in this
directory. Keep the entrypoint small and group checks with their related tools
rather than building the old superset module/scaffold system. A new domain
warrants a new file only when it adds meaningful behavior.

Keep CI workflows as thin wrappers around these Nix-defined tasks. PR
validation and the post-merge build both run `check:all`. Neither workflow
should reimplement a check in YAML. Run `devenv tasks run check:all` for the
same local gate as validation CI.
The gate covers OpenTofu formatting, backend-free initialization and TFLint,
Markdown, YAML, actionlint for GitHub Actions, and Nix formatting and static
checks. It also runs typos, Open Policy Agent deployment guardrails, tested Semgrep rules,
Trivy filesystem scanning, Vale prose and AI-writing detection, Git-history
and working-tree secret scanning, and `devenv test` shell smoke tests. Every declared check runs
in this gate. Each domain stays in its own module. A shared file format does
not make different tools one domain. Keep these tasks usable without GitHub or
Google Cloud credentials or remote Cloud Storage access. `check:tf` uses
`-lockfile=readonly` so provider lock changes remain explicit. `nix/nix.nix`
updates the whole pinned nixpkgs input. `nix/devenv.nix` updates only the CI
Devenv revision. Both file review-only proposals and must pass `check:all`.
Review the resulting tool versions before merging.

`nix/cache.nix` configures public Cachix pulls and tests fresh reads from
both binary caches after a trusted publish. The GitHub Actions setup handles
FlakeHub Cache authentication and Cachix uploads. No Nix module stores upload
credentials. Namespace cache tags separate PR, publisher, and readback stores.
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
