# Organization repository guide

This is the public `quantile-co/.github` repository, not an application's
`.github/` directory.

Repository memory: [Hindsight workflow](.agents/skills/hindsight/SKILL.md) and
[native configuration](.pi/hindsight.json).

**Maintain this file as a lightweight navigation index.** Only add or update
pointers to repository entry points. Link to the Hindsight workflow rather than
duplicating policies, runbooks or session notes here.

## Repository map

- [README.md](README.md): usage and development entry points.
- [profile/README.md](profile/README.md): approved public organization profile.
- [.envrc](.envrc): trusted direnv entry into the pinned shell.
- [flake.nix](flake.nix): Factory input, packages and development files.
- [package.json](package.json): workspace tasks and explicit skill synchronization.
- [apps/repo/](apps/repo/): repository checks, fixes and tests.
- [apps/github/](apps/github/): protected saved-plan workflow entry points.
- [apps/amp/](apps/amp/) and [.agents/](.agents/): Amp CLI and orb lifecycle hooks.
- [tf/](tf/): this repository's deployment root.
- [.github/workflows/](.github/workflows/): CI and protected deployment workflows.

## Deployment instructions

- Existing installation: [deploy](.agents/skills/deploy/SKILL.md).
- Confirmed new installation: [day-zero-deploy](.agents/skills/day-zero-deploy/SKILL.md).
