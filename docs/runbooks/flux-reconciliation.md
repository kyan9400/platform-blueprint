# Flux reconciliation runbook

## Detect

```bash
flux get sources git
flux get kustomizations
flux get helmreleases --all-namespaces
```

## Diagnose

```bash
flux logs --level=error --all-namespaces
kubectl -n flux-system describe gitrepository platform-blueprint
kubectl -n flux-system describe kustomization demo-workload
```

Common causes are an unreachable repository, invalid YAML, a missing CRD, a rejected admission request, or a failed Helm release.

## Recover

Re-run source and workload reconciliation after correcting desired state:

```bash
flux reconcile source git platform-blueprint
flux reconcile kustomization platform-controllers --with-source
flux reconcile kustomization policy-guardrails
flux reconcile kustomization observability
flux reconcile kustomization demo-workload
```

For a failed Helm release:

```bash
flux debug helmrelease podinfo -n platform-demo --show-status
kubectl -n platform-demo describe helmrelease podinfo
```

Prefer reverting the Git change. Use `flux suspend` only to create a bounded investigation window, and record the suspension.

## Verify

```bash
flux get all
kubectl -n platform-demo wait --for=condition=available deployment/podinfo-primary --timeout=180s
```

All Flux resources should report `Ready=True` at the same Git revision.
