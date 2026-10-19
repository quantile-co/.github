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
  exe = lib.getExe;
in
{
  imports = [
    inputs.factory.nixModules.default
    inputs.factory.devenvModules.files
  ];

  packages = [
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
    pkgs.git
    pkgs.ripgrep
  ];

  # Select only the declaration file in the store; runtime values stay in the shell.
  env.SECRETSPEC_FILE = "${config.quantile.secretspec.configFile}";
  enterShell = lib.mkBefore config.quantile.secretspec.shellHook;
  enterTest = ''
    set -euo pipefail
    for tool in tofu tflint nixfmt deadnix statix markdownlint-cli2 yamllint \
      actionlint shellcheck typos semgrep trivy vale secretspec gh gcloud jq \
      git rg pi qmd; do
      path=$(type -P "$tool") || { echo "Missing tool: $tool" >&2; exit 1; }
      case "$(readlink -f "$path")" in
        /nix/store/*) ;;
        *) echo "Tool is not from Nix: $tool ($path)" >&2; exit 1 ;;
      esac
    done
  '';

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
    ".pi/settings.json".source = config.quantile.pi.settingsFile;
    ".pi/skills/deploy".source = config.quantile.pi.skillsDir + "/deploy";
    ".pi/skills/day-zero-deploy".source = config.quantile.pi.skillsDir + "/day-zero-deploy";
    ".qmd/index.yml".source = config.quantile.qmd.configFile;
    ".semgrep".source = config.quantile.semgrep.rulesDir;
    ".semgrepignore".source = config.quantile.semgrep.ignoreFile;
  };

  tasks = {
    "git:hooks:install" = {
      description = "Explicitly install the shared pre-push hook for all worktrees.";
      after = [ "devenv:files" ];
      exec = exe config.quantile.git.prePush.install.package;
    };

    "check:all" = {
      description = "Run all checks without production credentials or a backend.";
      after = [ "devenv:files" ];
      exec = ''
        set -euo pipefail
        ${exe pkgs.nix} flake check .
        ${
          exe inputs.factory.packages.${pkgs.stdenv.hostPlatform.system}.check-devenv-locks
        } --flake-input factory flake.lock devenv.lock factory
        if [ "''${CI:-}" = true ]; then
          ${
            exe inputs.factory.packages.${pkgs.stdenv.hostPlatform.system}.check-devenv-locks
          } --git-index --flake-input factory flake.lock devenv.lock factory
        fi
        ${exe config.quantile.prek.check.package}
        ${exe config.quantile.nixfmt.check.package}
        ${exe config.quantile.deadnix.check.package}
        ${exe config.quantile.statix.check.package}
        ${exe config.quantile.editorconfig.check.package}
        ${exe config.quantile.markdownlint-cli2.check.package} '*.md' ':(exclude,glob).pi/memory/**'
        ${exe config.quantile.actionlint.check.package}
        ${exe config.quantile.semgrep.test.package}
        ${exe config.quantile.semgrep.check.package}
        ${exe config.quantile.trivy.check.package}
        ${exe config.quantile.typos.check.package}
        ${exe config.quantile.vale.check.package} '*.md' ':(exclude,glob)**/AGENTS.md' ':(exclude,glob).pi/memory/**' ':(exclude,glob).pi/skills/**'
        ${exe config.quantile.yamllint.check.package}
        ${exe config.quantile.taplo.check.package}
        ${exe config.quantile.taplo.format.package}
        git ls-files -z -- ${lib.escapeShellArg terraformSourceDir} |
          while IFS= read -r -d "" file; do
            case "$file" in *.tf|*.tofu) printf '%s\0' "$file" ;; esac
          done | xargs -0 -r ${exe config.quantile.opentofu.nonempty.package}
        TF_DIR=${lib.escapeShellArg terraformSourceDir} ${exe config.quantile.opentofu.format.package}
        TF_DIR=${lib.escapeShellArg terraformRoot} ${exe config.quantile.opentofu.check.package}
        : "''${DEVENV_STATE:?Devenv must provide isolated Terraform data}"
        tf_root=$(cd ${lib.escapeShellArg terraformRoot} && pwd -P)
        tf_hash=$(printf '%s' "$tf_root" | sha256sum | cut -d ' ' -f1)
        TF_DATA_DIR="$DEVENV_STATE/tofu-check/$tf_hash" \
          TF_DIR=${lib.escapeShellArg terraformRoot} ${exe config.quantile.tflint.check.package}
      '';
    };

    "fix:all" = {
      description = "Run all fixes.";
      after = [ "devenv:files" ];
      exec = ''
        TF_DIR=${lib.escapeShellArg terraformSourceDir} ${exe config.quantile.opentofu.fix.package}
        ${exe config.quantile.nixfmt.fix.package}
        ${exe config.quantile.taplo.fix.package}
        ${exe config.quantile.editorconfig.fix.package}
      '';
    };

    "test:all" = {
      description = "Run all tests.";
      after = [ "check:all" ];
      exec = "devenv test";
    };

    "plan:infrastructure" = {
      description = "Plan infrastructure.";
      env.TF_DIR = terraformRoot;
      exec = exe config.quantile.opentofu.plan.gcs.package;
    };

    "apply:infrastructure" = {
      description = "Apply infrastructure.";
      env.TF_DIR = terraformRoot;
      exec = exe config.quantile.opentofu.apply.gcs.package;
    };
  };
}
