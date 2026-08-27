#!/usr/bin/env bash
set -euo pipefail

for tool in docker kind kubectl flux; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "$tool is required" >&2
    exit 1
  }
done

cluster="platform-blueprint"

if ! kind get clusters | grep -Fxq "$cluster"; then
  kind create cluster --name "$cluster" --config clusters/local/kind.yaml
fi

current_context="$(kubectl config current-context)"
[[ "$current_context" == "kind-$cluster" ]] || {
  echo "Refusing to continue on context $current_context" >&2
  exit 1
}

flux install --version=v2.9.4
kubectl apply -k clusters/local

kubectl -n flux-system wait gitrepository/platform-blueprint \
  --for=condition=ready --timeout=180s

flux reconcile kustomization platform-controllers --with-source --timeout=15m
flux reconcile kustomization policy-guardrails --timeout=5m
flux reconcile kustomization observability --timeout=5m
flux reconcile kustomization demo-workload --timeout=10m

flux get kustomizations
echo "Platform ready. Run ./scripts/smoke-test.sh"
