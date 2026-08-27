#!/usr/bin/env bash
set -euo pipefail

command -v kubectl >/dev/null 2>&1 || {
  echo "kubectl is required" >&2
  exit 1
}

paths=(
  "clusters/local"
  "infrastructure/controllers"
  "policies"
  "observability"
  "apps/podinfo/overlays/local"
  "apps/podinfo/overlays/staging"
  "apps/podinfo/overlays/production"
)

for path in "${paths[@]}"; do
  rendered="$(kubectl kustomize "$path")"
  [[ -n "$rendered" ]] || {
    echo "empty render: $path" >&2
    exit 1
  }

  if grep -Eq '^[[:space:]]*image:[[:space:]]+[^[:space:]]*:latest([[:space:]]|$)' <<<"$rendered"; then
    echo "mutable workload image in $path" >&2
    exit 1
  fi

  if grep -Eq '^kind:[[:space:]]+Secret$' <<<"$rendered"; then
    echo "plain Kubernetes Secret found in $path" >&2
    exit 1
  fi

  echo "rendered $path"
done

echo "manifest verification passed"
