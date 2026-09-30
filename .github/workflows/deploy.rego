package main

import rego.v1

# The deployment workflow must stay manual, plan-only by default, and scoped to
# protected main/prod. This checks source YAML, not cloud IAM or a live plan.
deploy if input.jobs.deploy

# conftest's YAML 1.1 parser converts the workflow key `on` into `true`.
# Fixture tests use the ordinary JSON spelling, so accept either parse result.
dispatch := object.get(input, "on", object.get(input, "true", {}))

deny contains "Deployment must be manual and plan-only by default" if {
  deploy
  not dispatch.workflow_dispatch.inputs.apply.default == false
}

deny contains "Deployment must not have automatic triggers" if {
  deploy
  count(object.keys(dispatch)) != 1
}

deny contains "Deployment must require protected main and a maintainer" if {
  deploy
  not contains(input.jobs.deploy.if, "refs/heads/main")
}

deny contains "Deployment must require protected main and a maintainer" if {
  deploy
  not contains(input.jobs.deploy.if, "GH_MAINTAINERS")
}

deny contains "Deployment must use the prod environment" if {
  deploy
  not input.jobs.deploy.environment == "prod"
}

has_opt_in_apply if {
  some step in input.jobs.deploy.steps
  step.name == "Apply exact plan"
  step.if == "inputs.apply"
}

deny contains "Apply must be opt-in" if {
  deploy
  not has_opt_in_apply
}
