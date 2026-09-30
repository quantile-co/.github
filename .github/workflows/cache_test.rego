package main

import rego.v1

cache_publish_steps := [
  {"uses": "cachix/cachix-action@pinned", "with": {"authToken": "${{ secrets.CACHIX_AUTH_TOKEN }}", "skipAddingSubstituter": true}},
  {"uses": "DeterminateSystems/flakehub-cache-action@pinned"},
]

safe_cache_build := {
  "name": "Build",
  "on": {"push": {"branches": ["main"]}},
  "jobs": {"publish-caches": {
    "if": "github.event_name == 'push' && github.ref == 'refs/heads/main'",
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

test_cache_rejects_mutable_store_reuse if {
  every label in ["nscloud-ubuntu-24.04-amd64-4x8-with-cache", "nscloud-cache-tag-publish"] {
    "Persistent runner caches require a reviewed security design" in deny with input as {"jobs": {"reader": {"runs-on": label}}}
  }
  "Persistent runner caches require a reviewed security design" in deny with input as {"runs": {"steps": [{"uses": "namespacelabs/nscloud-cache-action@pinned"}]}}
}

test_cache_rejects_signature_bypasses if {
  every command in ["nix copy --no-check-sigs", "nix copy --option require-sigs false", "require-sigs = false", "nix copy --from https://example.com?trusted=true"] {
    "Cache verification must not bypass signatures" in deny with input as {"jobs": {"reader": {"steps": [{"run": command}]}}}
  }
}
