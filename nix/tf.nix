{ pkgs, ... }:
{
  # The pinned nixpkgs revision supplies the same OpenTofu locally and in CI.
  packages = with pkgs; [
    jq
    opentofu
    tflint
  ];

  tasks = {
    "check:tf" = {
      description = "Format, initialize without the GCS backend, validate, and lint tf/infrastructure/.";
      exec = ''
        set -euo pipefail
        export TF_DATA_DIR="$DEVENV_STATE/tofu-check"
        tofu -chdir=tf/infrastructure fmt -check -recursive
        tofu -chdir=tf/infrastructure init -backend=false -input=false -lockfile=readonly
        tofu -chdir=tf/infrastructure validate
        tflint --chdir=tf/infrastructure
      '';
    };

    # Deployment tasks run only from protected, manual Plan/Apply workflows with
    # the prod SecretSpec profile. Keep the saved plan in tf/infrastructure/ for the same run.
    "tf:init" = {
      description = "Initialize the production state backend.";
      exec = ''
        set -euo pipefail
        tofu -chdir=tf/infrastructure init -input=false -reconfigure \
          -backend-config="bucket=$TF_STATE_BUCKET" \
          -backend-config="prefix=repository/prod"
      '';
    };

    "tf:validate" = {
      description = "Validate production Terraform with its remote backend.";
      exec = "tofu -chdir=tf/infrastructure validate";
    };

    "tf:plan" = {
      description = "Write a production plan and print only resource actions to public CI logs.";
      exec = ''
        set -euo pipefail
        tofu -chdir=tf/infrastructure plan -input=false -out=plan.tfplan >/dev/null
        tofu -chdir=tf/infrastructure show -json plan.tfplan |
          jq -r '[.resource_changes[]? | select(.change.actions != ["no-op"]) | "\(.address): \(.change.actions | join(","))"] | if length == 0 then "No changes." else .[] end'
        # Attribute names, not values: safe to print in public workflow logs.
        tofu -chdir=tf/infrastructure show -json plan.tfplan |
          jq -r '.resource_changes[]? | select(.address == "module.github.github_repository.self") | (.change.before // {}) as $before | (.change.after // {}) as $after | ($before + $after | keys[]) | select($before[.] != $after[.]) | "  repository attribute: \(.)"'
      '';
    };

    "tf:apply" = {
      description = "Apply only the plan created in this run.";
      exec = "tofu -chdir=tf/infrastructure apply -input=false -auto-approve plan.tfplan";
    };
  };
}
