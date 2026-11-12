locals {
  project_owners = [{
    gcp_email   = "aj@quantile.co"
    gh_username = "aj-welch"
  }]
  project_members = []
}

module "hindsight" {
  source = "git::https://github.com/quantile-co/factory.git//tf/modules/project/hindsight?ref=5ff0a140390cd040fdafdc5ad2881c3638b51afe"

  providers = {
    restapi = restapi.hindsight
  }

  bank_id = "quantile-co--github"
  name    = "quantile-co/.github"
}

# trivy:ignore:AVD-GIT-0001
module "gh" {
  source = "git::https://github.com/quantile-co/factory.git//tf/modules/project/github?ref=a2205ee819a322ff03d4ff6de93120ec80165f79"

  repo_name       = ".github"
  description     = "Quantile organization profile."
  visibility      = "public"
  has_issues      = false
  owners          = [for person in local.project_owners : person.gh_username]
  members         = [for person in local.project_members : person.gh_username]
  required_checks = ["All"]
  environments    = ["prod"]
}

module "gcp" {
  source = "git::https://github.com/quantile-co/factory.git//tf/modules/project/gcp?ref=8f966fb1d6062a52754a3d47b9f2791a617e2849"

  project_prefix    = "github"
  folder_id         = "145094075590"
  billing_account   = "0120D4-52D1E2-9C3D0D"
  tf_state_location = "US"
  wif_pool          = var.gcp_wif_pool
  owners            = [for person in local.project_owners : person.gcp_email]
  members           = [for person in local.project_members : person.gcp_email]

  gh_repo_id   = module.gh.repo_id
  gh_owner_ids = module.gh.owner_ids
}
