# Canary rollback runbook

## Trigger

Use this runbook when a canary is stuck, Flagger reports failed checks, or user-facing error/latency SLOs breach during a release.

## Assess

```bash
kubectl -n platform-demo get canary podinfo
kubectl -n platform-demo describe canary podinfo
kubectl -n platform-demo get deploy,po,svc,ingress
kubectl -n platform-demo logs deploy/podinfo --tail=100
```

Confirm whether the failure is application behavior, missing metrics, ingress health, or an admission rejection.

## Stop progression

Suspend GitOps reconciliation while the incident is active:

```bash
flux suspend kustomization demo-workload
```

Flagger normally rolls back automatically after five failed checks. If traffic remains on the canary, force reconciliation of the last known-good Git revision:

```bash
git revert <bad-commit>
git push origin main
flux resume kustomization demo-workload
flux reconcile kustomization demo-workload --with-source
```

Do not patch the generated `podinfo-primary` deployment. Flagger owns it and will overwrite manual changes.

## Verify recovery

```bash
kubectl -n platform-demo wait --for=condition=available deployment/podinfo-primary --timeout=180s
kubectl -n platform-demo get canary podinfo
kubectl -n flagger-system exec deploy/flagger-loadtester -- \
  curl -fsS http://podinfo.platform-demo:9898/readyz
```

Success criteria:

- primary deployment is available;
- canary phase is `Succeeded` or the rejected revision is scaled to zero;
- five-minute error ratio is below 1%;
- p99 request duration is below 500 ms.

## Follow-up

Record the failed revision, alert timestamps, decision metrics, customer impact, and corrective action. Re-enable reconciliation only after the repository contains the intended state.
