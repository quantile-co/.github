#!/usr/bin/env bash
# Temporary, read-only preflight for the initial saved-plan deployment.
set -euo pipefail
set +x
umask 077

: "${GCP_TF_STATE_BUCKET:?Set the existing state bucket}"
test "${TF_BACKEND_PREFIX:?Set the backend prefix}" = repository/prod
case "${GH_UNLOCK_REVIEWED_LOCK:-false}" in
    true | false) ;;
    *) echo 'Invalid lock-inspection mode.' >&2; exit 1 ;;
esac

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
    metageneration=$(jq -er '.metageneration | tostring | select(test("^[1-9][0-9]*$"))' "$scratch/lock.json")
    gcloud storage cp "$lock#$generation" "$scratch/lock.payload" --quiet \
        > "$scratch/copy.log" 2>&1 || {
        echo 'Backend lock exists, but its pinned contents could not be read.' >&2
        exit 1
    }
    if [ "${GH_UNLOCK_REVIEWED_LOCK:-false}" = true ]; then
        # One-time authorization for the exact cancelled-run lock reviewed privately.
        # Neither its ID nor the provider payload is committed or printed.
        jq -e --arg path "$lock" '
            .Operation == "OperationTypePlan" and .Path == $path and
            (.ID | type == "string")
        ' "$scratch/lock.payload" > /dev/null
        fingerprint=$(jq -nc --slurpfile metadata "$scratch/lock.json" \
            --slurpfile payload "$scratch/lock.payload" '
            $metadata[0] as $m | $payload[0] as $lock |
            [($m.generation | tostring), ($m.metageneration | tostring),
                $m.timeCreated, $m.updated, $lock.ID, $lock.Who,
                $lock.Created, $lock.Path, $lock.Operation]
        ' | sha256sum | cut -d ' ' -f1)
        test "$fingerprint" = acef00dadf176bc998cce35134af82f7cee4730b2bf9f44560107b1c4e528949 || {
            echo 'Backend lock differs from the one privately reviewed; stop.' >&2
            exit 1
        }
        : "${GH_TOKEN:?Only a job-scoped token may verify the cancelled producer}"
        : "${GITHUB_REPOSITORY:?Run on the protected repository}"
        gh api "repos/$GITHUB_REPOSITORY/actions/runs/39226445495" > "$scratch/producer.json"
        jq -e '
            .path == ".github/workflows/plan.yaml" and
            .head_sha == "17ad43dab976ff24250e08add4ec4b8516ac00b9" and
            .run_started_at == "2026-10-19T08:57:11Z" and
            .status == "completed" and .conclusion == "cancelled"
        ' "$scratch/producer.json" > /dev/null || {
            echo 'Original lock holder is not a completed cancelled Plan.' >&2
            exit 1
        }
        gcloud storage rm "$lock" --if-generation-match="$generation" \
            --if-metageneration-match="$metageneration" --quiet \
            > "$scratch/unlock.log" 2>&1 || {
            echo 'Exact-generation lock removal failed; stop before Plan.' >&2
            exit 1
        }
        if gcloud storage objects describe "$lock" --raw --format='value(name)' \
            > "$scratch/after.json" 2> "$scratch/after.err"; then
            echo 'A backend lock still exists; stop before Plan.' >&2
            exit 1
        fi
        if ! grep -Eiq '(^|[^0-9])404([^0-9]|$)|not[ -]?found' "$scratch/after.err"; then
            echo 'Cannot confirm the reviewed lock is absent; stop before Plan.' >&2
            exit 1
        fi
        echo 'Only the reviewed abandoned lock was removed; Plan must acquire its own lock.'
        exit 0
    fi
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
    if [ "${GH_UNLOCK_REVIEWED_LOCK:-false}" = true ]; then
        echo 'The reviewed lock is already absent; use an ordinary Plan dispatch.' >&2
        exit 1
    fi
    echo 'No backend lock object found. OpenTofu must still acquire its own lock.'
else
    echo 'Backend lock status could not be verified; stop.' >&2
    exit 1
fi
