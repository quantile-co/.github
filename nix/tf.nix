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
      description = "Format, initialize without the GCS backend, validate, and lint tf/.";
      exec = ''
        set -euo pipefail
        tofu -chdir=tf fmt -check -recursive
        tofu -chdir=tf init -backend=false -input=false -lockfile=readonly
        tofu -chdir=tf validate
        tflint --chdir=tf
      '';
    };

    # Deployment tasks run only from the protected, manual workflow with its
    # deploy SecretSpec profile. Keep the saved plan in tf/ for the same run.
    "tf:init" = {
      description = "Initialize the production state backend.";
      exec = ''
        set -euo pipefail
        tofu -chdir=tf init -input=false -reconfigure \
          -backend-config="bucket=$TF_STATE_BUCKET" \
          -backend-config="prefix=repository/prod"
      '';
    };

    "tf:validate" = {
      description = "Validate production Terraform with its remote backend.";
      exec = "tofu -chdir=tf validate";
    };

    "tf:plan" = {
      description = "Write a production plan and print only resource actions to public CI logs.";
      exec = ''
        set -euo pipefail
        tofu -chdir=tf plan -input=false -out=plan.tfplan >/dev/null
        tofu -chdir=tf show -json plan.tfplan |
          jq -r '[.resource_changes[]? | select(.change.actions != ["no-op"]) | "\(.address): \(.change.actions | join(","))"] | if length == 0 then "No changes." else .[] end'
      '';
    };

    "tf:apply" = {
      description = "Apply only the plan created in this run.";
      exec = "tofu -chdir=tf apply -input=false -auto-approve plan.tfplan";
    };
  };
}
