#!/usr/bin/env bash
set -euo pipefail

pnpm run check
if (($# == 0)); then set -- README.md profile/README.md; fi
check-vale "$@"
