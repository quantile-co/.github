package main

import rego.v1

safe_plan := {
  "name": "Plan",
  "on": {"workflow_dispatch": {}},
  "jobs": {
    "plan": {
      "if": "github.ref == 'refs/heads/main' && contains(fromJSON(vars.GH_MAINTAINERS), github.actor)",
      "environment": "prod",
      "steps": [{"run": "devenv tasks run tf:plan"}],
    },
  },
}

safe_apply := {
  "name": "Apply",
  "on": {"workflow_dispatch": {}},
  "jobs": {
    "apply": {
      "if": "github.ref == 'refs/heads/main' && contains(fromJSON(vars.GH_MAINTAINERS), github.actor)",
      "environment": "prod",
      "steps": [{"run": "devenv tasks run tf:plan"}, {"run": "devenv tasks run tf:apply"}],
    },
  },
}

test_safe_plan if {
  count(deny) == 0 with input as safe_plan
}

test_safe_apply if {
  count(deny) == 0 with input as safe_apply
}

test_conftest_yaml_true_key if {
  parsed := object.union(safe_plan, {"true": safe_plan.on})
  count(deny) == 0 with input as object.remove(parsed, {"on"})
}

test_accepts_environment_object if {
  job := object.union(safe_plan.jobs.plan, {"environment": {"name": "prod"}})
  candidate := {"name": "Plan", "on": safe_plan.on, "jobs": {"plan": job}}
  count(deny) == 0 with input as candidate
}

test_rejects_missing_environment if {
  job := object.remove(safe_plan.jobs.plan, {"environment"})
  unsafe := {"name": "Plan", "on": safe_plan.on, "jobs": {"plan": job}}
  "Repository settings must use the prod environment" in deny with input as unsafe
}

test_rejects_invalid_environment_forms if {
  every environment in [null, {}, {"name": "dev"}] {
    job := object.union(safe_plan.jobs.plan, {"environment": environment})
    unsafe := {"name": "Plan", "on": safe_plan.on, "jobs": {"plan": job}}
    "Repository settings must use the prod environment" in deny with input as unsafe
  }
}

test_rejects_missing_guard if {
  job := object.remove(safe_plan.jobs.plan, {"if"})
  unsafe := {"name": "Plan", "on": safe_plan.on, "jobs": {"plan": job}}
  "Repository settings must require protected main and a maintainer" in deny with input as unsafe
}

test_rejects_bypassed_guard if {
  every guard in [true, "true || (github.ref == 'refs/heads/main' && contains(fromJSON(vars.GH_MAINTAINERS), github.actor))"] {
    job := object.union(safe_plan.jobs.plan, {"if": guard})
    unsafe := {"name": "Plan", "on": safe_plan.on, "jobs": {"plan": job}}
    "Repository settings must require protected main and a maintainer" in deny with input as unsafe
  }
}

test_rejects_renamed_deployment_jobs if {
  every workflow in [safe_plan, safe_apply] {
    job := workflow.jobs[lower(workflow.name)]
    unsafe := {"name": workflow.name, "on": workflow.on, "jobs": {"deployment": job}}
    "Plan and Apply must keep their protected job IDs" in deny with input as unsafe
  }
}

test_rejects_renamed_workflow_and_job if {
  every name in ["plan.yaml", "apply.yaml"] {
    unsafe := {"name": "Other", "on": {"push": {}}, "jobs": {"deploy": {"steps": [{"run": "tf:plan"}]}}}
    result := deny with input as unsafe with data.conftest as {"file": {"name": name}}
    "Plan and Apply must keep their protected job IDs" in result
    "Repository settings must run manually" in result
    "Repository settings must use the prod environment" in result
  }
}

test_rejects_missing_deployment_jobs if {
  every name in ["Plan", "Apply"] {
    "Plan and Apply must keep their protected job IDs" in deny with input as {"name": name, "on": {"workflow_dispatch": {}}}
  }
}

test_rejects_extra_deployment_jobs if {
  unsafe := object.union(safe_apply, {"jobs": {"unprotected": {"steps": [{"run": "tofu apply -auto-approve"}]}}})
  "Plan and Apply must keep their protected job IDs" in deny with input as unsafe
  "Repository settings must require protected main and a maintainer" in deny with input as unsafe
}

test_rejects_push_trigger if {
  unsafe := object.union(safe_plan, {"on": {"workflow_dispatch": {}, "push": {}}})
  "Repository settings must run manually" in deny with input as unsafe
}

test_rejects_unprotected_job if {
  unsafe := object.union(safe_plan, {"jobs": {"plan": object.union(safe_plan.jobs.plan, {"if": "github.ref == 'refs/heads/main'"})}})
  "Repository settings must require protected main and a maintainer" in deny with input as unsafe
}

test_rejects_wrong_environment if {
  unsafe := object.union(safe_plan, {"jobs": {"plan": object.union(safe_plan.jobs.plan, {"environment": "dev"})}})
  "Repository settings must use the prod environment" in deny with input as unsafe
}

test_rejects_plan_without_plan if {
  unsafe := object.union(safe_plan, {"jobs": {"plan": object.union(safe_plan.jobs.plan, {"steps": []})}})
  "Repository settings must create a plan" in deny with input as unsafe
}

test_rejects_plan_with_apply if {
  unsafe := object.union(safe_plan, {"jobs": {"plan": object.union(safe_plan.jobs.plan, {"steps": [{"run": "tf:plan"}, {"run": "tf:apply"}]})}})
  "Plan must not apply" in deny with input as unsafe
}

test_rejects_apply_without_apply if {
  unsafe := object.union(safe_apply, {"jobs": {"apply": object.union(safe_apply.jobs.apply, {"steps": [{"run": "tf:plan"}]})}})
  "Apply must use its saved plan" in deny with input as unsafe
}

test_rejects_apply_before_plan if {
  unsafe := object.union(safe_apply, {"jobs": {"apply": object.union(safe_apply.jobs.apply, {"steps": [{"run": "tf:apply"}, {"run": "tf:plan"}]})}})
  "Apply must use its saved plan" in deny with input as unsafe
}
