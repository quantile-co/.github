{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  terraformSourceDir = "tf";
  terraformRoot = "tf/infrastructure";
  dependabotFile = config.quantile.dependabot.withUpdates [
    "github-actions"
    "opentofu"
    "nix"
  ];
  exe = lib.getExe;
in
{
  imports = [
    inputs.factory.nixModules.default
    inputs.factory.devenvModules.files
    inputs."dot-github".nixModules.default
  ];

  cachix.pull = [
    "quantile-co"
    "cachix"
    "pre-commit-hooks"
    "go-overlay"
  ];

  packages = [
    config.quantile.bash.package
    config.quantile.coreutils.package
    config.quantile.diffutils.package
    config.quantile.nix.package
    config.quantile.opentofu.package
    config.quantile.tflint.package
    config.quantile.taplo.package
    config.quantile.gcloud.package
    config.quantile.gh.package
    config.quantile.actionlint.package
    config.quantile.git.lfs.package
    config.quantile.git.prePush.package
    config.quantile.prek.package
    config.quantile.prek.tools.package
    config.quantile.shellcheck.package
    config.quantile.shfmt.package
    config.quantile.jq.package
    config.quantile.pi.package
    config.quantile.qmd.package
    config.quantile.trivy.package
    config.quantile.typos.package
    config.quantile.vale.package
    config.quantile.yamllint.package
    config.quantile.semgrep.package
    config.quantile.secretspec.package
    config.quantile.markdownlint-cli2.package
    config.quantile.nixfmt.package
    config.quantile.deadnix.package
    config.quantile.statix.package
    config.quantile.git.package
    pkgs.ripgrep
  ];

  # Scan with pinned Terraform and security packs alongside local rules.
  quantile.semgrep.check.configs = lib.attrVals [
    "owasp-top-ten"
    "secrets"
    "security-audit"
    "terraform"
  ] config.quantile.semgrep.packs;

  # Select only the declaration file in the store; runtime values stay in the shell.
  env.SECRETSPEC_FILE = "${config.quantile.secretspec.configFile}";
  enterShell = lib.mkBefore config.quantile.secretspec.shellHook;

  files = {
    ".editorconfig".source = config.quantile.editorconfig.configFile;
    ".editorconfig-checker.json".source = config.quantile.editorconfig.checker.configFile;
    ".markdownlint-cli2.jsonc".source = config.quantile.markdownlint-cli2.configFile;
    ".pre-commit-config.yaml".source = config.quantile.prek.configFile;
    ".cz.toml".source = config.quantile.commitizen.configFile;
    ".shellcheckrc".source = config.quantile.shellcheck.configFile;
    ".tflint.hcl".source = config.quantile.tflint.configFile;
    "taplo.toml".source = config.quantile.taplo.configFile;
    "trivy.yaml".source = config.quantile.trivy.configFile;
    "typos.toml".source = config.quantile.typos.configFile;
    ".vale.ini".source = config.quantile.vale.configFile;
    "etc/vale/styles".source = config.quantile.vale.stylesDirectory;
    ".yamllint.yaml".source = config.quantile.yamllint.configFile;
    ".github/actionlint.yaml".source = config.quantile.actionlint.configFile;
    # GitHub reads a tracked copy; an ignored Nix-store symlink is not enough.
    ".github/dependabot.yml" = {
      source = dependabotFile;
      copyMode = "copy";
    };
    ".pi/settings.json".source = config.quantile.pi.settingsFile;
    ".pi/skills/devenv-tasks".source = config.quantile.pi.skillsDir + "/devenv-tasks";
    ".pi/skills/deploy".source = config.quantile.pi.skillsDir + "/deploy";
    ".pi/skills/day-zero-deploy".source = config.quantile.pi.skillsDir + "/day-zero-deploy";
    ".qmd/index.yml".source = config.quantile.qmd.configFile;
    ".semgrep".source = config.quantile.semgrep.rulesDir;
    ".semgrepignore".source = config.quantile.semgrep.ignoreFile;
  };

  tasks = {
    "install:git:hooks" = {
      description = "Install Git hooks.";
      after = [ "devenv:files" ];
      exec = exe config.quantile.git.prePush.install.package;
    };

    "check:all" = {
      description = "Run all checks.";
      after = [ "devenv:files" ];
      exec = ''
        set -euo pipefail
        # Validate the flake and the tracked native Dependabot copy.
        ${exe pkgs.nix} flake check .
        ${exe config.quantile.dependabot.check.package} ${dependabotFile}
        ${exe inputs.factory.packages.${pkgs.stdenv.hostPlatform.system}.check-devenv-locks}
        # Read-only checks: formatting fixes are only in fix:all.
        ${exe config.quantile.prek.check.package}
        ${exe config.quantile.nixfmt.check.package}
        ${exe config.quantile.deadnix.check.package}
        ${exe config.quantile.statix.check.package}
        ${exe config.quantile.editorconfig.check.package}
        ${exe config.quantile.markdownlint-cli2.check.package} '*.md' ':(exclude,glob).pi/memory/**'
        ${exe config.quantile.actionlint.check.package}
        # Test the native Semgrep policy fixtures before scanning the source.
        ${exe config.quantile.semgrep.test.package}
        ${exe config.quantile.semgrep.check.package}
        ${exe config.quantile.trivy.check.package}
        ${exe config.quantile.typos.check.package}
        ${exe config.quantile.vale.check.package} '*.md' ':(exclude,glob)**/AGENTS.md' ':(exclude,glob).pi/memory/**' ':(exclude,glob).pi/skills/**'
        ${exe config.quantile.yamllint.check.package}
        ${exe config.quantile.taplo.check.package}
        ${exe config.quantile.taplo.format.package}
        ${exe config.quantile.opentofu.nonempty.package} ${lib.escapeShellArg terraformSourceDir}
        TF_DIR=${lib.escapeShellArg terraformSourceDir} ${exe config.quantile.opentofu.format.package}
        TF_DIR=${lib.escapeShellArg terraformRoot} ${exe config.quantile.opentofu.check.package}
        TF_DIR=${lib.escapeShellArg terraformRoot} ${exe config.quantile.tflint.check.package}
      '';
    };

    "fix:all" = {
      description = "Run all fixes.";
      after = [ "devenv:files" ];
      exec = ''
        set -euo pipefail
        TF_DIR=${lib.escapeShellArg terraformSourceDir} ${exe config.quantile.opentofu.fix.package}
        ${exe config.quantile.nixfmt.fix.package}
        ${exe config.quantile.taplo.fix.package}
        ${exe config.quantile.editorconfig.fix.package}
      '';
    };

    "test:all" = {
      description = "Run all tests.";
      after = [ "check:all" ];
      exec = "${exe config.quantile.vale.check.package} README.md profile/README.md";
    };

    "plan:infrastructure" = {
      description = "Plan infrastructure.";
      env.TF_DIR = terraformRoot;
      exec = exe config.quantile.opentofu.plan.package;
    };

    "apply:infrastructure" = {
      description = "Apply infrastructure.";
      env.TF_DIR = terraformRoot;
      exec = exe config.quantile.opentofu.apply.package;
    };
  };
}
