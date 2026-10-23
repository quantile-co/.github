{
  description = "Quantile organization profile";

  # Moving refs propose updates; flake.lock fixes exact revisions.
  inputs = {
    factory.url = "github:quantile-co/factory/main";
    nixpkgs.follows = "factory/nixpkgs";
  };

  outputs =
    inputs:
    let
      inherit (inputs) factory;
    in
    factory.lib.mkFlake {
      inherit (inputs) nixpkgs;
      modules = [ factory.nixModules.default ];
      nixpkgsConfig.allowUnfree = true;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, factory }:
        let
          copy = source: {
            inherit source;
            mode = "copy";
          };
          workflow =
            name:
            let
              source = builtins.readFile factory.github.workflows.${name}.configFile;
              from = [ "group: factory-production" ];
              to = [ "group: organization-production" ];
            in
            assert pkgs.lib.assertMsg (pkgs.lib.all (
              text: pkgs.lib.hasInfix text source
            ) from) "Organization workflow template no longer contains its expected patch points";
            pkgs.writeText "${name}.yaml" (builtins.replaceStrings from to source);
          dependabotFile = pkgs.writeText "dependabot.yml" (
            builtins.replaceStrings [ "directory: /tf/infrastructure" ] [ "directory: /tf" ] (
              builtins.readFile factory.dependabot.configFile
            )
          );
        in
        {
          # Public flake packages for workflow entry points.
          packages = {
            inherit (pkgs) direnv;
            github-workflow-plan = factory.github.workflows.plan.package;
            github-workflow-apply = factory.github.workflows.apply.package;
          };

          # Only tools and configuration used to develop this repository.
          devShell = {
            packages =
              (with pkgs; [
                bash
                coreutils
                diffutils
                direnv
                git
                git-lfs
                jq
                nix
                nodejs_24
                pnpm
                gh
                google-cloud-sdk
                opentofu
                tflint
                actionlint
                semgrep
                shellcheck
                shfmt
                taplo
                trivy
                typos
                vale
                yamllint
              ])
              ++ [ inputs.factory.packages.${pkgs.stdenv.hostPlatform.system}.herdr ]
              ++ (with factory; [
                pi.package
                qmd.package
                amp.package
                clickhouse.package
                clickhousectl.package
                hunk.package
                langfuse.package
                tailscale.package
                prek.package
                prek.tools.package
                dependabot.check.package
                prek.check.package
                nixfmt.check.package
                deadnix.check.package
                statix.check.package
                editorconfig.check.package
                shellcheck.check.package
                shfmt.check.package
                markdownlint-cli2.check.package
                actionlint.check.package
                semgrep.test.package
                semgrep.check.package
                trivy.check.package
                typos.check.package
                vale.check.package
                yamllint.check.package
                taplo.check.package
                taplo.format.package
                opentofu.nonempty.package
                opentofu.format.package
                opentofu.check.package
                tflint.check.package
                opentofu.fix.package
                nixfmt.fix.package
                shfmt.fix.package
                taplo.fix.package
                editorconfig.fix.package
              ]);

            # Committed regular files; direnv refreshes copy entries on shell entry.
            files = {
              "README.md" = {
                source = factory.readme.withProject {
                  name = "Quantile organization profile";
                  description = "Quantile organization profile";
                };
                mode = "seed";
              };
              ".gitignore" = copy factory.git.ignoreFile;
              ".envrc" = copy factory.direnv.configFile;
              ".husky/pre-push" = copy factory.husky.prePushFile;
              ".editorconfig" = copy factory.editorconfig.configFile;
              ".editorconfig-checker.json" = copy factory.editorconfig.checker.configFile;
              ".markdownlint-cli2.jsonc" = copy factory.markdownlint-cli2.configFile;
              ".pre-commit-config.yaml" = copy factory.prek.configFile;
              ".cz.toml" = copy factory.commitizen.configFile;
              ".shellcheckrc" = copy factory.shellcheck.configFile;
              ".tflint.hcl" = copy factory.tflint.configFile;
              "taplo.toml" = copy factory.taplo.configFile;
              "trivy.yaml" = copy factory.trivy.configFile;
              "typos.toml" = copy factory.typos.configFile;
              ".vale.ini" = copy factory.vale.configFile;
              ".vale" = copy factory.vale.stylesDirectory;
              ".yamllint.yaml" = copy factory.yamllint.configFile;
              ".github/actionlint.yaml" = copy factory.actionlint.configFile;
              ".github/workflows/check.yaml" = copy factory.github.workflows.check.configFile;
              ".github/workflows/test.yaml" = copy factory.github.workflows.test.configFile;
              ".github/workflows/plan.yaml" = copy (workflow "plan");
              ".github/workflows/apply.yaml" = copy (workflow "apply");
              ".github/dependabot.yml" = copy dependabotFile;
              ".pi/settings.json" = copy factory.pi.settingsFile;
              ".pi/extensions" = copy factory.pi.extensionsDir;
              ".pi/skills/deploy" = copy (factory.pi.skillsDir + "/deploy");
              ".pi/skills/day-zero-deploy" = copy (factory.pi.skillsDir + "/day-zero-deploy");
              ".qmd/index.yml" = {
                source = factory.qmd.configFile;
                mode = "seed";
              };
              ".semgrep/tf" = copy (factory.semgrep.rulesDir + "/tf");
              ".semgrep/packs/terraform.yaml" = copy factory.semgrep.packs.terraform;
              ".semgrep/packs/github-actions.yaml" = copy factory.semgrep.packs.github-actions;
              ".semgrepignore" = copy factory.semgrep.ignoreFile;
            };
          };
        };
    };
}
