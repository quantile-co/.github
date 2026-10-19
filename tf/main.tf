# Reuse Factory's project modules at a reviewed immutable revision. This root
# keeps the existing .github backend and repository-specific choices.
# trivy:ignore:AVD-GIT-0001
module "github" {
  source = "git::https://github.com/quantile-co/factory.git//tf/modules/project/github?ref=e85fa302ef67dbed5baa93a0f8becd00079aa24d"

  # Existing GitHub resources use this aliased provider in the remote state.
  providers = {
    github  = github.quantile_co
    restapi = restapi
  }

  repository_name = ".github"
  description     = "Quantile organization profile."
  visibility      = "public"
  has_issues      = false
  maintainers     = var.gh_maintainers
  environments    = ["build", "prod"]
}

module "gcp" {
  source = "git::https://github.com/quantile-co/factory.git//tf/modules/project/gcp?ref=e85fa302ef67dbed5baa93a0f8becd00079aa24d"

  project_prefix  = "github"
  folder_id       = var.gcp_folder_id
  billing_account = var.gcp_billing_account
  wif_pool        = var.gcp_wif_pool
  # This repository applies fresh plans in the same job; it has no human
  # cross-workflow saved-plan reviewers to grant object access to.
  maintainers = []

  repository_id             = module.github.repository_id
  repository_maintainer_ids = module.github.maintainer_ids
}
