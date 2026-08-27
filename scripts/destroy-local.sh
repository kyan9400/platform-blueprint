#!/usr/bin/env bash
set -euo pipefail

cluster="platform-blueprint"

if kind get clusters | grep -Fxq "$cluster"; then
  kind delete cluster --name "$cluster"
else
  echo "cluster $cluster does not exist"
fi
