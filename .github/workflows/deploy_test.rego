package main

import rego.v1

safe := {
  "name": "Deploy repository settings",
  "on": {"workflow_dispatch": {"inputs": {"apply": {"default": false}}}},
  "jobs": {
    "deploy": {
      "if": "github.ref == 'refs/heads/main' && contains(fromJSON(vars.GH_MAINTAINERS), github.actor)",
      "environment": "prod",
      "steps": [{"name": "Apply exact plan", "if": "inputs.apply"}],
    },
  },
}

test_safe if {
  count(deny) == 0 with input as safe
}

test_rejects_default_apply if {
  unsafe := object.union(safe, {"on": {"workflow_dispatch": {"inputs": {"apply": {"default": true}}}}})
  "Deployment must be manual and plan-only by default" in deny with input as unsafe
}

test_conftest_yaml_true_key if {
  parsed := object.union(safe, {"true": safe.on})
  parsed_without_on := object.remove(parsed, {"on"})
  count(deny) == 0 with input as parsed_without_on
}

test_rejects_push_trigger if {
  unsafe := object.union(safe, {"on": {"workflow_dispatch": {"inputs": {"apply": {"default": false}}}, "push": {}}})
  "Deployment must not have automatic triggers" in deny with input as unsafe
}

test_rejects_unprotected_job if {
  unsafe := object.union(safe, {"jobs": {"deploy": {"if": "github.ref == 'refs/heads/main'", "environment": "prod", "steps": [{"name": "Apply exact plan", "if": "inputs.apply"}]}}})
  "Deployment must require protected main and a maintainer" in deny with input as unsafe
}

test_rejects_unguarded_apply if {
  unsafe := object.union(safe, {"jobs": {"deploy": {"if": "github.ref == 'refs/heads/main' && vars.GH_MAINTAINERS", "environment": "prod", "steps": [{"name": "Apply exact plan"}]}}})
  "Apply must be opt-in" in deny with input as unsafe
}

test_rejects_wrong_environment if {
  unsafe := object.union(safe, {"jobs": {"deploy": {"if": "github.ref == 'refs/heads/main' && vars.GH_MAINTAINERS", "environment": "dev", "steps": [{"name": "Apply exact plan", "if": "inputs.apply"}]}}})
  "Deployment must use the prod environment" in deny with input as unsafe
}
