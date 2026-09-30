package main

import rego.v1

# Plan and Apply must remain manual and scoped to protected main/prod.
# This checks workflow source, not cloud IAM or a live Terraform plan.
# conftest's YAML 1.1 parser converts the workflow key `on` into `true`.
dispatch := object.get(input, "on", object.get(input, "true", {}))

protected_kinds contains kind if {
  kind := {"Plan": "plan", "Apply": "apply"}[input.name]
}

# Conftest supplies the filename independently of editable workflow/job names.
protected_kinds contains kind if {
  kind := {"plan.yaml": "plan", "apply.yaml": "apply"}[data.conftest.file.name]
}

protected_kinds contains kind if {
  some kind in {"plan", "apply"}
  input.jobs[kind]
}

protected_workflow if {
  count(protected_kinds) > 0
}

protected_jobs contains job if {
  protected_workflow
  some job in input.jobs
}

deny contains "Plan and Apply must keep their protected job IDs" if {
  some kind in protected_kinds
  object.keys(object.get(input, "jobs", {})) != {kind}
}

deny contains "Repository settings must run manually" if {
  protected_workflow
  count(object.keys(dispatch)) != 1
}

deny contains "Repository settings must run manually" if {
  protected_workflow
  not dispatch.workflow_dispatch
}

valid_deployment_guard(job) if {
  is_string(job.if)
  normalized := trim_space(regex.replace(job.if, "\\s+", " "))
  normalized == "github.ref == 'refs/heads/main' && contains(fromJSON(vars.GH_MAINTAINERS), github.actor)"
}

deny contains "Repository settings must require protected main and a maintainer" if {
  some job in protected_jobs
  not valid_deployment_guard(job)
}

prod_environment(job) if {
  job.environment == "prod"
}

prod_environment(job) if {
  job.environment.name == "prod"
}

deny contains "Repository settings must use the prod environment" if {
  some job in protected_jobs
  not prod_environment(job)
}

has_task(job, task) if {
  some step in job.steps
  contains(object.get(step, "run", ""), task)
}

deny contains "Repository settings must create a plan" if {
  some job in protected_jobs
  not has_task(job, "tf:plan")
}

deny contains "Plan must not apply" if {
  job := input.jobs.plan
  has_task(job, "tf:apply")
}

deny contains "Apply must use its saved plan" if {
  job := input.jobs.apply
  not has_task(job, "tf:apply")
}

deny contains "Apply must use its saved plan" if {
  job := input.jobs.apply
  plan_index := [i | some i, step in job.steps; contains(object.get(step, "run", ""), "tf:plan")][0]
  apply_index := [i | some i, step in job.steps; contains(object.get(step, "run", ""), "tf:apply")][0]
  plan_index >= apply_index
}
