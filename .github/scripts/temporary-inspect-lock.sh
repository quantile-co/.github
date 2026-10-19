#!/usr/bin/env bash
# Temporary, read-only preflight for the initial saved-plan deployment.
set -euo pipefail
set +x
umask 077

: "${GCP_TF_STATE_BUCKET:?Set the existing state bucket}"
test "${TF_BACKEND_PREFIX:?Set the backend prefix}" = repository/prod

scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT

# Do not report bucket metadata or lock contents to public Actions logs.
gcloud storage buckets describe "gs://$GCP_TF_STATE_BUCKET" --raw --format=json \
    > "$scratch/bucket.json" 2> "$scratch/bucket.err" || {
    echo 'Could not verify the existing state bucket.' >&2
    exit 1
}
jq -e '.iamConfiguration.publicAccessPrevention == "enforced" and
    .iamConfiguration.uniformBucketLevelAccess.enabled == true' \
    "$scratch/bucket.json" > /dev/null || {
    echo 'The existing state bucket does not meet private-bucket requirements.' >&2
    exit 1
}

lock="gs://$GCP_TF_STATE_BUCKET/$TF_BACKEND_PREFIX/default.tflock"
if gcloud storage objects describe "$lock" --raw --format=json \
    > "$scratch/lock.json" 2> "$scratch/lock.err"; then
    # Keep lock identity/holder and timestamps private. Pin the payload read to
    # the inspected generation, encrypt it, and still fail before Plan starts.
    generation=$(jq -er '.generation | tostring | select(test("^[1-9][0-9]*$"))' "$scratch/lock.json")
    gcloud storage cp "$lock#$generation" "$scratch/lock.payload" --quiet \
        > "$scratch/copy.log" 2>&1 || {
        echo 'Backend lock exists, but its pinned contents could not be read.' >&2
        exit 1
    }
    recipient=$(< .github/plan-review.agepub)
    [[ "$recipient" =~ ^age1[0-9a-z]{58}$ ]] || {
        echo 'Invalid reviewed public diagnostic recipient.' >&2
        exit 1
    }
    jq -n --slurpfile metadata "$scratch/lock.json" --rawfile payload "$scratch/lock.payload" \
        '{metadata: $metadata[0], payload: $payload}' > "$scratch/diagnostic.json"
    encrypted="${RUNNER_TEMP:?}/encrypted-backend-lock"
    test ! -e "$encrypted"
    mkdir -m 0700 -- "$encrypted"
    age -r "$recipient" -o "$encrypted/diagnostic.json.age" "$scratch/diagnostic.json" || {
        rm -rf -- "$encrypted"
        echo 'Could not encrypt the private backend-lock diagnostic.' >&2
        exit 1
    }
    echo 'Backend lock exists; encrypted read-only diagnostic prepared, Plan blocked.' >&2
    exit 1
fi
if grep -Eiq '(^|[^0-9])404([^0-9]|$)|not[ -]?found' "$scratch/lock.err"; then
    echo 'No backend lock object found. OpenTofu must still acquire its own lock.'
else
    echo 'Backend lock status could not be verified; stop.' >&2
    exit 1
fi
