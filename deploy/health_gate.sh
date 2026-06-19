#!/usr/bin/env bash
set -euo pipefail
for i in 1 2 3; do
  if curl -fsS "$HEALTH_URL"; then exit 0; fi
  sleep 5
done
echo 'health gate failed; rolling back' >&2
exit 1
