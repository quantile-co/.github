terraform {
  required_version = ">= 1.12.3, < 2.0.0"

  required_providers {
    github = {
      source  = "registry.opentofu.org/integrations/github"
      version = "= 6.13.0"
    }
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "8.8.1"
    }
    random = {
      source  = "registry.opentofu.org/hashicorp/random"
      version = "= 3.9.1"
    }
    restapi = {
      source  = "registry.terraform.io/Mastercard/restapi"
      version = "= 3.0.0"
    }
  }
}
