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
if gcloud storage objects describe "$lock" --raw --format='value(name)' \
    > "$scratch/lock.json" 2> "$scratch/lock.err"; then
    echo 'Backend lock exists; stop and investigate before planning.' >&2
    exit 1
fi
if grep -Eiq '(^|[^0-9])404([^0-9]|$)|not[ -]?found' "$scratch/lock.err"; then
    echo 'No backend lock object found. OpenTofu must still acquire its own lock.'
else
    echo 'Backend lock status could not be verified; stop.' >&2
    exit 1
fi
