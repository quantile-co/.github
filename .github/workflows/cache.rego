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

deny contains "Configure Cachix reads additively through the installer" if {
  some _, step in walk(input)
  is_object(step)
  startswith(object.get(step, "uses", ""), "cachix/cachix-action@")
  settings := object.get(step, "with", {})
  not object.get(settings, "skipAddingSubstituter", false) in {true, "true"}
}

deny contains "Cachix publishing requires explicit roots, including warm paths" if {
  some job_id, job in input.jobs
  cache_publisher(job_id)
  some step in job.steps
  cache_uploader(step)
  settings := object.get(step, "with", {})
  object.get(settings, "pathsToPush", "") == ""
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

# No mutable runner-store reuse until server-enforced access controls and
# credential exclusion have been reviewed. Tags are not authorization.
deny contains "Persistent runner caches require a reviewed security design" if {
  some _, value in walk(input)
  is_string(value)
  regex.match("nscloud-cache-action@|nscloud-cache-tag-|nscloud-.*-with-cache", value)
}

deny contains "Cache verification must not bypass signatures" if {
  some _, value in walk(input)
  is_string(value)
  regex.match("--no-check-sigs|require-sigs[^\\n]*false|[?&]trusted=(1|true)", value)
}
