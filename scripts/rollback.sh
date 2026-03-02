#!/bin/bash
set -e
SERVICE_NAME="${1}"
REVISION="${2}"
if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 SERVICE_NAME [REVISION]"
  echo "Example: $0 user-service 2"
  exit 1
fi
if [ -n "$REVISION" ]; then
  kubectl rollout undo deployment/"$SERVICE_NAME" -n production --to-revision="$REVISION"
else
  kubectl rollout undo deployment/"$SERVICE_NAME" -n production
fi
kubectl rollout status deployment/"$SERVICE_NAME" -n production --timeout=300s
