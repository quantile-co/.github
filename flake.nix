{
  description = "Quantile organization repository";

  inputs = {
    factory.url = "github:quantile-co/factory/92ef45786d2f003559ffc9d41f56bc7a8763c7d9";
    nixpkgs.follows = "factory/nixpkgs";
    devenv.follows = "factory/devenv";
    devenv-cli.follows = "factory/devenv-cli";
    git-hooks.follows = "factory/git-hooks";
    go-overlay.follows = "factory/go-overlay";
    llm-agents.follows = "factory/llm-agents";
    mk-shell-bin.follows = "factory/mk-shell-bin";
    nix2container.follows = "factory/nix2container";
  };

  outputs = { factory, ... }: {
    packages = builtins.mapAttrs (_: packages: {
      inherit (packages) devenv-cli;
    }) factory.packages;
  };
}
