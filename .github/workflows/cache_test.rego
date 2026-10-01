package main

import rego.v1

cache_publish_steps := [
  {"uses": "cachix/cachix-action@pinned", "with": {
    "authToken": "${{ secrets.CACHIX_AUTH_TOKEN }}",
    "skipAddingSubstituter": true,
    "pathsToPush": "${{ steps.cache-roots.outputs.paths }}",
  }},
]

safe_cache_build := {
  "name": "Build",
  "on": {"push": {"branches": ["main"]}},
  "jobs": {"publish-caches": {
    "if": "github.event_name == 'push' && github.ref == 'refs/heads/main'",
    "environment": "cache",
    "steps": cache_publish_steps,
  }},
}

test_cache_main_publisher if {
  count(deny) == 0 with input as safe_cache_build
}

test_cache_yaml_true_key if {
  parsed := object.union(safe_cache_build, {"true": safe_cache_build.on})
  count(deny) == 0 with input as object.remove(parsed, {"on"})
}

test_cache_reader if {
  reader := {"runs": {"steps": [{"uses": "cachix/cachix-action@pinned", "with": {"skipPush": "true", "skipAddingSubstituter": true}}]}}
  count(deny) == 0 with input as reader
}

test_cache_rejects_replacing_installer_configuration if {
  unsafe := {"runs": {"steps": [{"uses": "cachix/cachix-action@pinned", "with": {"skipPush": "true"}}]}}
  "Configure Cachix reads additively through the installer" in deny with input as unsafe
}

test_cache_rejects_pr_publisher if {
  unsafe := object.union(safe_cache_build, {"on": {"pull_request": {}}})
  "Only the trusted main publisher may upload caches" in deny with input as unsafe
}

test_cache_rejects_unguarded_publisher if {
  base := object.remove(safe_cache_build, {"jobs"})
  unsafe := object.union(base, {"jobs": {"publish-caches": {"steps": cache_publish_steps}}})
  "Only the trusted main publisher may upload caches" in deny with input as unsafe
}

test_cache_rejects_reader_uploads if {
  every step in cache_publish_steps {
    unsafe := object.union(safe_cache_build, {"jobs": {"verify-caches": {"steps": [step]}}})
    "Only the trusted main publisher may upload caches" in deny with input as unsafe
  }
}

test_cache_rejects_shared_uploads if {
  every step in cache_publish_steps {
    "Shared setup must never upload caches" in deny with input as {"runs": {"steps": [step]}}
  }
}

test_cache_rejects_reader_write_token if {
  unsafe := {"jobs": {"reader": {"env": {"TOKEN": "${{ secrets.CACHIX_AUTH_TOKEN }}"}}}}
  "Only the publisher may receive the Cachix write token" in deny with input as unsafe
}

cache_mount_step := {"uses": "namespacelabs/nscloud-cache-action@pinned", "with": {
  "path": "/nix",
  "spacectl-version": "0.12.3",
  "spacectl-system-binary": "ignore",
}}

cache_install_step := {"uses": "cachix/install-nix-action@pinned", "with": {"install_options": "--no-daemon"}}

cache_store_job := {
  "runs-on": "namespace-profile-quantile",
  "steps": [cache_mount_step, cache_install_step],
}

cache_check(job) := {
  "name": "Check",
  "on": {"pull_request": {}},
  "jobs": {"all-checks": job},
}

test_cache_allows_pr_store_reuse if {
  # Namespace enforces main-only commits; a PR event is not a blanket veto.
  count(deny) == 0 with input as cache_check(cache_store_job)
}

test_cache_allows_non_publishing_maintenance if {
  job := object.union(cache_store_job, {"runs-on": namespace_reader_labels})
  count(deny) == 0 with input as {"name": "Update", "jobs": {"update": job}}
}

test_cache_requires_non_publishing_maintenance if {
  "Unreviewed dependency updates must discard snapshot changes" in deny with input as {"name": "Update", "jobs": {"update": cache_store_job}}
}

test_cache_allows_deployment_snapshot_updates if {
  every workflow in [safe_plan, safe_apply] {
    job_id := lower(workflow.name)
    job := object.union(workflow.jobs[job_id], {
      "runs-on": "namespace-profile-quantile",
      "steps": array.concat(cache_store_job.steps, workflow.jobs[job_id].steps),
    })
    candidate := object.union(workflow, {"jobs": {job_id: job}})
    count(deny) == 0 with input as candidate
  }
}

test_cache_allows_trusted_main_maintenance_updates if {
  count(deny) == 0 with input as {"name": "Update", "jobs": {"dependabot-automerge": cache_store_job}}
}

test_cache_rejects_custom_identity if {
  every labels in [
    "nscloud-ubuntu-24.04-amd64-4x8-with-cache",
    "namespace-profile-quantile;overrides.cache-tag=shared",
    ["namespace-profile-quantile", "nscloud-cache-tag-shared"],
    "namespace-profile-default",
  ] {
    job := object.union(cache_store_job, {"runs-on": labels})
    "Use the shared Namespace profile without custom cache tags" in deny with input as cache_check(job)
  }
}

test_cache_rejects_extra_persisted_paths_and_unpinned_tools if {
  every settings in [
    {"path": "/nix\n~/.config"},
    {"path": "~/.config"},
    {"cache": "nix"},
    {"detect": "true"},
    {"spacectl-version": "latest"},
    {"spacectl-system-binary": "prefer"},
  ] {
    mount := object.union(cache_mount_step, {"with": object.union(cache_mount_step.with, settings)})
    job := object.union(cache_store_job, {"steps": [mount, cache_install_step]})
    "Mount only /nix with the required pinned Namespace integration" in deny with input as cache_check(job)
  }
}

test_cache_rejects_optional_mount if {
  every settings in [{"if": "false"}, {"continue-on-error": true}] {
    mount := object.union(cache_mount_step, settings)
    job := object.union(cache_store_job, {"steps": [mount, cache_install_step]})
    "Mount only /nix with the required pinned Namespace integration" in deny with input as cache_check(job)
  }
}

test_cache_requires_mount_before_install if {
  every steps in [[cache_install_step], [cache_install_step, cache_mount_step]] {
    job := object.union(cache_store_job, {"steps": steps})
    "Mount the active store before installing Nix" in deny with input as cache_check(job)
  }
}

test_cache_requires_single_user_install if {
  every options in ["", "--daemon", "--no-daemon --daemon"] {
    installer := object.union(cache_install_step, {"with": {"install_options": options}})
    job := object.union(cache_store_job, {"steps": [cache_mount_step, installer]})
    "Persistent stores require the standard single-user Nix installer" in deny with input as cache_check(job)
  }
}

test_cache_rejects_mount_in_shared_setup if {
  "Mount persistent stores directly in workflow jobs, not shared setup" in deny with input as {"runs": {"steps": [cache_mount_step]}}
}

test_cache_requires_publisher_environment if {
  every environment in ["", "prod"] {
    job := object.union(safe_cache_build.jobs["publish-caches"], {"environment": environment})
    unsafe := object.union(safe_cache_build, {"jobs": {"publish-caches": job}})
    "Cachix publication requires the main-only cache environment" in deny with input as unsafe
  }
}

test_cache_rejects_implicit_store_scan if {
  step := object.union(cache_publish_steps[0], {"with": {"pathsToPush": ""}})
  unsafe := object.union(safe_cache_build, {"jobs": {"publish-caches": {"steps": [step]}}})
  "Cachix publishing requires explicit roots, including warm paths" in deny with input as unsafe
}

test_cache_rejects_determinate_and_flakehub if {
  every action in ["determinate-nix-action", "nix-installer-action", "flakehub-cache-action"] {
    step := {"uses": sprintf("DeterminateSystems/%s@pinned", [action])}
    "Public CI uses standard Nix and Cachix, not Determinate or FlakeHub" in deny with input as {"runs": {"steps": [step]}}
  }
}

test_cache_rejects_signature_bypasses if {
  every command in ["nix copy --no-check-sigs", "nix copy --option require-sigs false", "require-sigs = false", "nix copy --from https://example.com?trusted=true"] {
    "Cache verification must not bypass signatures" in deny with input as {"jobs": {"reader": {"steps": [{"run": command}]}}}
  }
}
