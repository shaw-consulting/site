#!/bin/sh
# One-time setup in each local clone (Git deliberately does not auto-install hooks).
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo 'Run this in a cloned Git repository.' >&2
  exit 1
fi

CURRENT=$(git -C "$ROOT" config --local --get core.hooksPath || :)
if [ -n "$CURRENT" ] && [ "$CURRENT" != '.githooks' ]; then
  echo "Existing hook path is '$CURRENT'. Not overwriting it." >&2
  echo 'Integrate the build command with your existing hooks instead.' >&2
  exit 1
fi

git -C "$ROOT" config --local core.hooksPath .githooks
sh "$ROOT/scripts/build-logo.sh"
printf '%s\n' 'Enabled .githooks for this clone.'
