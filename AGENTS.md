# Organization repository agent guide

This is the public `quantile-co/.github` repository, not the app's `.github/` directory. `profile/README.md` is the approved
public organization profile. The root `README.md` describes this repository. Preserve the profile's
approved copy and the root README's centered header and horizontal navigation.

Read the scoped guides before changing their areas:

- [`.github/AGENTS.md`](.github/AGENTS.md): workflow runners, cache, and protected Apply.
- [`nix/AGENTS.md`](nix/AGENTS.md): local development and checks.
- [`tf/AGENTS.md`](tf/AGENTS.md): repository settings and state infrastructure.

`tf/` manages this repository's settings and its dedicated state infrastructure,
not organization-wide administration, app hosting, or domain name system
management. Never add private topology, credentials, or unrelated
infrastructure here.

## Development

Local prerequisites are Determinate Nix, direnv, and devenv. All repository
checks run with `devenv tasks run check:all` without cloud credentials or a
remote backend. `devenv.nix` is only the import entrypoint. Domain code lives
under `nix/`. Git ignores `.envrc.local`, which contains optional local
credentials.

Prefix project-defined environment variables, secrets, and parameters with
their owning platform or component. Keep tool-required names such as
`GH_TOKEN` and `TF_VAR_*`. Use `GH_` for custom GitHub credentials because
GitHub reserves `GITHUB_` for its own secrets and workflow variables.

## Knowledge maintenance

Keep this guide self-contained. The parent workspace, app repo, old
backups, and research notes may move or disappear. This repo must not depend on
them. Update the applicable scoped guide when implementation decisions or
failure modes change. Keep human READMEs short and put agent implementation
knowledge here, not in the public profile. Never commit secrets, state, or
plans.
