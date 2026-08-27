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

forward_log="$(mktemp)"
kubectl -n platform-demo port-forward service/podinfo 18080:9898 \
  >"$forward_log" 2>&1 &
forward_pid=$!
cleanup() {
  kill "$forward_pid" 2>/dev/null || true
  rm -f "$forward_log"
}
trap cleanup EXIT

service_ready=false
for _ in $(seq 1 30); do
  if curl --connect-timeout 2 --max-time 5 -fsS \
    http://127.0.0.1:18080/readyz >/dev/null; then
    service_ready=true
    break
  fi
  sleep 2
done

if [[ "$service_ready" != "true" ]]; then
  cat "$forward_log" >&2
  echo "Podinfo service did not answer through kubectl port-forward" >&2
  exit 1
fi

curl --retry 12 --retry-all-errors --retry-delay 2 \
  --connect-timeout 2 --max-time 10 -fsS \
  -H "Host: podinfo.local" \
  http://127.0.0.1/readyz >/dev/null

kubectl -n platform-demo get canary podinfo
echo "smoke test passed"
