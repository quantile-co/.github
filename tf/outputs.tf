output "gcp_tf_state_bucket" {
  description = "Existing versioned GCS bucket for this repository's Terraform state."
  value       = module.gcp.tf_state_bucket
}

output "gcp_tf_state_project_id" {
  description = "Existing project ID for this repository's state infrastructure."
  value       = module.gcp.tf_state_project_id
}

output "gh_repository_id" {
  description = "Immutable numeric ID of the .github repository."
  value       = module.github.repository_id
}
