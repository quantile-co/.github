# Organization repository guide

This is the public `quantile-co/.github` repository, not an application's
`.github/` directory.

Read [project memory](.pi/memory/MEMORY.md) before working here. It holds
repository rules, decisions, preferences and operational context. Source,
tests and current workflows take precedence over historical notes.

**Maintain this file as a lightweight navigation index.** Only add or update
pointers to repository entry points. Put durable guidance in `MEMORY.md`
instead of duplicating policies, runbooks or session notes here.

## Repository map

- [README.md](README.md): usage and development entry points.
- [profile/README.md](profile/README.md): approved public organization profile.
- [.envrc](.envrc): pinned Devenv CLI and local shell bootstrap.
- [devenv.nix](devenv.nix): shell wiring and check/fix/test/deployment tasks.
- [flake.nix](flake.nix): pinned Factory inputs.
- [tf/infrastructure/](tf/infrastructure/): this repository's deployment root.
- [nix/default.nix](nix/default.nix): local workflow-template materialization.
- [.github/workflows/](.github/workflows/): CI and protected deployment workflows.

## Deployment instructions

- Existing installation: [deploy](.pi/skills/deploy/SKILL.md).
- Confirmed new installation: [day-zero-deploy](.pi/skills/day-zero-deploy/SKILL.md).
