#!/usr/bin/env bash
set -euo pipefail

expected_context="kind-platform-blueprint"
current_context="$(kubectl config current-context)"
[[ "$current_context" == "$expected_context" ]] || {
  echo "Refusing to test context $current_context; expected $expected_context" >&2
  exit 1
}

deployment="podinfo-primary"
if ! kubectl -n platform-demo get deployment "$deployment" >/dev/null 2>&1; then
  deployment="podinfo"
fi

kubectl -n platform-demo wait deployment/"$deployment" \
  --for=condition=available --timeout=180s

endpoint=""
for _ in $(seq 1 36); do
  endpoint="$(kubectl -n platform-demo get endpointslice \
    -l kubernetes.io/service-name=podinfo \
    -o jsonpath='{.items[0].endpoints[0].addresses[0]}' 2>/dev/null || true)"
  [[ -n "$endpoint" ]] && break
  sleep 5
done

[[ -n "$endpoint" ]] || {
  echo "Podinfo service has no ready endpoint" >&2
  exit 1
}

loadtester="$(kubectl -n flagger-system get deployment \
  -l app.kubernetes.io/name=loadtester \
  -o jsonpath='{.items[0].metadata.name}')"

[[ -n "$loadtester" ]] || {
  echo "Flagger load tester was not found" >&2
  exit 1
}

kubectl -n flagger-system exec deployment/"$loadtester" -- \
  curl --connect-timeout 5 --max-time 15 -fsS \
  http://podinfo.platform-demo:9898/readyz

kubectl -n flagger-system exec deployment/"$loadtester" -- \
  curl --connect-timeout 5 --max-time 15 -fsS \
  -H "Host: podinfo.local" \
  http://ingress-nginx-controller.ingress-nginx/readyz

kubectl -n platform-demo get canary podinfo
echo "smoke test passed"
