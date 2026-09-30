{ pkgs, ... }:
{
  # The nixpkgs revision in devenv.yaml supplies OpenTofu 1.12.3, matching CI.
  packages = with pkgs; [
    opentofu
    tflint
  ];

  tasks."check:tf" = {
    description = "Format, initialize without the GCS backend, validate, and lint tf/.";
    exec = ''
      set -euo pipefail
      tofu -chdir=tf fmt -check -recursive
      tofu -chdir=tf init -backend=false -input=false -lockfile=readonly
      tofu -chdir=tf validate
      tflint --chdir=tf
    '';
  };
}
