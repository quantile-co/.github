# Credentials come from the protected runtime, never Terraform variables.
provider "google" {}

# Keep the provider address used by existing state while resources move into
# the module; no token is stored in Terraform variables or state.
provider "github" {
  alias = "quantile_co"
  owner = "quantile-co"
}

provider "restapi" {
  uri = "https://api.github.com"

  headers = {
    Accept               = "application/vnd.github+json"
    X-GitHub-Api-Version = "2022-11-28"
  }
}
