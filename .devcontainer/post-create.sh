#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# The bind mount is owned by a host UID, so git refuses the repo as dubious ownership.
git config --global --get-all safe.directory | grep -qxF "$PWD" \
  || git config --global --add safe.directory "$PWD"

bin/setup --skip-server
bin/setup-hooks
