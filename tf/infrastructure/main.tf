# trivy:ignore:AVD-GIT-0001
module "github" {
  source = "git::https://github.com/quantile-co/factory.git//tf/modules/project/github?ref=aa1f81936ef7e12bb77cc2f1ddbbc96039fb177f"

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
  source = "git::https://github.com/quantile-co/factory.git//tf/modules/project/gcp?ref=aa1f81936ef7e12bb77cc2f1ddbbc96039fb177f"

  project_prefix  = "github"
  folder_id       = var.gcp_folder_id
  billing_account = var.gcp_billing_account
  wif_pool        = var.gcp_wif_pool
  maintainers     = var.gcp_maintainers

  repository_id             = module.github.repository_id
  repository_maintainer_ids = module.github.maintainer_ids
}
