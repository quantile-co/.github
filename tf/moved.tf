# These moves adopt the existing .github production state into Factory's
# reusable modules. Never create another state project, bucket or repository.
moved {
  from = random_id.state
  to   = module.gcp.random_id.state
}

moved {
  from = google_project.state
  to   = module.gcp.google_project.state
}

moved {
  from = google_project_service.storage
  to   = module.gcp.google_project_service.storage
}

moved {
  from = google_project_iam_member.pipeline_owner
  to   = module.gcp.google_project_iam_member.pipeline_owner
}

moved {
  from = google_storage_bucket.state
  to   = module.gcp.google_storage_bucket.state
}

moved {
  from = github_repository.self
  to   = module.github.github_repository.self
}

moved {
  from = github_actions_repository_permissions.self
  to   = module.github.github_actions_repository_permissions.self
}

moved {
  from = github_repository_vulnerability_alerts.self
  to   = module.github.github_repository_vulnerability_alerts.self
}

moved {
  from = github_repository_dependabot_security_updates.self
  to   = module.github.github_repository_dependabot_security_updates.self
}

moved {
  from = github_branch_protection.main
  to   = module.github.github_branch_protection.main
}

moved {
  from = github_repository_environment.prod
  to   = module.github.github_repository_environment.main["prod"]
}

moved {
  from = github_repository_environment.build
  to   = module.github.github_repository_environment.main["build"]
}

moved {
  from = github_repository_environment_deployment_policy.build_main
  to   = module.github.github_repository_environment_deployment_policy.main["build"]
}
