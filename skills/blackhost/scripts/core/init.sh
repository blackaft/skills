#!/usr/bin/env bash
set -euo pipefail

BLACKHOST_ENTRYPOINT="${BASH_SOURCE[0]}"
BLACKHOST_BOOTSTRAP="$(cd "$(dirname "$BLACKHOST_ENTRYPOINT")" && pwd)/helpers/run.sh"

# shellcheck disable=SC1091
. "$BLACKHOST_BOOTSTRAP"

blackhost_bootstrap "$BLACKHOST_ENTRYPOINT"
blackhost_run "$@"
