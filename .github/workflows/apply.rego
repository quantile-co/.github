package main

import rego.v1

# Plan and Apply must remain manual and scoped to protected main/prod.
# This checks workflow source, not cloud IAM or a live Terraform plan.
# conftest's YAML 1.1 parser converts the workflow key `on` into `true`.
dispatch := object.get(input, "on", object.get(input, "true", {}))

protected_jobs contains job if {
  some kind in {"plan", "apply"}
  job := input.jobs[kind]
}

deny contains "Repository settings must run manually" if {
  some _ in protected_jobs
  count(object.keys(dispatch)) != 1
}

deny contains "Repository settings must run manually" if {
  some _ in protected_jobs
  not dispatch.workflow_dispatch
}

deny contains "Repository settings must require protected main and a maintainer" if {
  some job in protected_jobs
  not contains(job.if, "refs/heads/main")
}

deny contains "Repository settings must require protected main and a maintainer" if {
  some job in protected_jobs
  not contains(job.if, "GH_MAINTAINERS")
}

deny contains "Repository settings must use the prod environment" if {
  some job in protected_jobs
  job.environment != "prod"
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
