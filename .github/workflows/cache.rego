package main

import rego.v1

cache_dispatch := object.get(input, "on", object.get(input, "true", {}))

cache_publisher(job_id) if {
  input.name == "Build"
  job_id == "publish-caches"
  object.keys(cache_dispatch) == {"push"}
  cache_dispatch.push.branches == ["main"]
  input.jobs[job_id].if == "github.event_name == 'push' && github.ref == 'refs/heads/main'"
}

cache_push_disabled(step) if {
  step.with.skipPush in {true, "true"}
}

deny contains "Public CI uses standard Nix and Cachix, not Determinate or FlakeHub" if {
  some _, step in walk(input)
  is_object(step)
  regex.match("^DeterminateSystems/(determinate-nix-action|nix-installer-action|flakehub-cache-action)@", object.get(step, "uses", ""))
}

cache_uploader(step) if {
  startswith(object.get(step, "uses", ""), "cachix/cachix-action@")
  not cache_push_disabled(step)
}

deny contains "Only the trusted main publisher may upload caches" if {
  some job_id, job in input.jobs
  some step in job.steps
  cache_uploader(step)
  not cache_publisher(job_id)
}

deny contains "Cachix publication requires the main-only build environment" if {
  some _, job in input.jobs
  some step in job.steps
  cache_uploader(step)
  object.get(job, "environment", "") != "build"
}

deny contains "Shared setup must never upload caches" if {
  some step in input.runs.steps
  cache_uploader(step)
}

deny contains "Only the publisher may receive the Cachix write token" if {
  some job_id, job in input.jobs
  some _, value in walk(job)
  is_string(value)
  contains(value, "secrets.CACHIX_AUTH_TOKEN")
  not cache_publisher(job_id)
}

# These rules check the workflow contract, not Namespace's deployed settings.
# The shared profile must enforce cache_volume_settings[].allow_commit_from_branch
# = ["main"]. Default profile/repository isolation must remain enabled.
nix_store_mount(step) if {
  startswith(object.get(step, "uses", ""), "namespacelabs/nscloud-cache-action@")
}

nix_installer(step) if {
  startswith(object.get(step, "uses", ""), "cachix/install-nix-action@")
}

namespace_reader_labels := ["namespace-profile-quantile", "nscloud-cache-exp-do-not-commit"]

namespace_profile(job) if {
  job["runs-on"] == "namespace-profile-quantile"
}

namespace_profile(job) if {
  job["runs-on"] == namespace_reader_labels
}

nix_store_mount_configured(step) if {
  step.with.path == "/nix"
  step.with["spacectl-system-binary"] == "ignore"
  regex.match("^[0-9]+\\.[0-9]+\\.[0-9]+$", step.with["spacectl-version"])
  object.get(step.with, "cache", "") == ""
  object.get(step.with, "detect", "") == ""
  object.get(step, "if", "") == ""
  object.get(step, "continue-on-error", false) == false
}

nix_store_mounted_before(job, install_index) if {
  some mount_index, step in job.steps
  mount_index < install_index
  nix_store_mount(step)
  nix_store_mount_configured(step)
}

deny contains "Mount only /nix with the required pinned Namespace integration" if {
  some _, job in input.jobs
  some step in job.steps
  nix_store_mount(step)
  not nix_store_mount_configured(step)
}

deny contains "Use the shared Namespace profile without custom cache tags" if {
  some _, job in input.jobs
  some step in job.steps
  nix_store_mount(step)
  not namespace_profile(job)
}

# This job evaluates new, unreviewed inputs even though its workflow is on main.
# Other jobs, including Plan/Apply, rely on the profile's main-only commit policy.
deny contains "Unreviewed dependency updates must discard snapshot changes" if {
  input.name == "Update"
  job := input.jobs.update
  some step in job.steps
  nix_store_mount(step)
  job["runs-on"] != namespace_reader_labels
}

deny contains "Mount the active store before installing Nix" if {
  some _, job in input.jobs
  some install_index, step in job.steps
  nix_installer(step)
  not nix_store_mounted_before(job, install_index)
}

deny contains "Persistent stores require the standard single-user Nix installer" if {
  some _, job in input.jobs
  some step in job.steps
  nix_installer(step)
  object.get(object.get(step, "with", {}), "install_options", "") != "--no-daemon"
}

deny contains "Mount persistent stores directly in workflow jobs, not shared setup" if {
  some step in input.runs.steps
  nix_store_mount(step)
}

deny contains "Cache verification must not bypass signatures" if {
  some _, value in walk(input)
  is_string(value)
  regex.match("--no-check-sigs|require-sigs[^\\n]*false|[?&]trusted=(1|true)", value)
}
