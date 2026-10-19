# trivy:ignore:AVD-GIT-0001
module "github" {
  source = "git::https://github.com/quantile-co/factory.git//tf/modules/project/github?ref=c0fd54801c96766033ba8fd59cb8fb126044660c"

  repository_name = ".github"
  description     = "Quantile organization profile."
  visibility      = "public"
  has_issues      = false
  maintainers     = var.gh_maintainers
  # GitHub reports reusable jobs as "caller / called"; both jobs are "All".
  required_checks = ["All / All"]
  environments    = ["prod"]
}

module "gcp" {
  source = "git::https://github.com/quantile-co/factory.git//tf/modules/project/gcp?ref=c0fd54801c96766033ba8fd59cb8fb126044660c"

  project_prefix  = "github"
  folder_id       = var.gcp_folder_id
  billing_account = var.gcp_billing_account
  wif_pool        = var.gcp_wif_pool
  maintainers     = var.gcp_maintainers

  repository_id             = module.github.repository_id
  repository_maintainer_ids = module.github.maintainer_ids
}
