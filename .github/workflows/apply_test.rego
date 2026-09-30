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
