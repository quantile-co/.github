<!-- markdownlint-disable MD041 -->
<br>

<div align="center">
  <h1>Quantile organization profile</h1>
  <p><em>GitHub organization profile and repository settings</em></p>
  <p>
    <a href="#prerequisites">Prerequisites</a> ·
    <a href="#development">Development</a>
  </p>
</div>

<br>
<!-- markdownlint-enable MD041 -->

## Prerequisites

Local toolchain:

- [Determinate Nix](https://docs.determinate.systems/)
- [direnv](https://direnv.net/docs/installation.html)
- [devenv](https://devenv.sh/getting-started/)

## Development

This repository contains the public profile displayed for the
[`quantile-co`](https://github.com/quantile-co) organization and the OpenTofu
configuration for this repository's settings and state infrastructure.

After cloning, run `direnv allow` once, then:

```sh
devenv tasks run check:all
```

Or use `devenv shell` without direnv. The checks run locally without cloud
credentials or remote state access.
