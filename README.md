<!-- markdownlint-disable MD041 -->
<br>

<div align="center">
  <h1>Quantile organization profile</h1>
  <p><em>GitHub organization profile</em></p>
  <p>
    <a href="#prerequisites">Prerequisites</a> ·
    <a href="#development">Development</a>
  </p>
</div>

<br>
<!-- markdownlint-enable MD041 -->

## Prerequisites

- [Nix](https://nix.dev/install-nix.html)
- [direnv](https://direnv.net/docs/installation.html)
- [devenv](https://devenv.sh/getting-started/)

After cloning, allow direnv to load the development environment:

```sh
direnv allow
```

The devenv shell provides all other project tools.

## Development

```sh
devenv tasks run check:all
```
