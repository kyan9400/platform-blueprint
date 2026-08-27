# Threat model

## Protected assets

- integrity of desired cluster state;
- availability of the demo workload during releases;
- integrity of third-party artifacts;
- cloud credentials and Terraform state;
- cluster-admin capabilities.

## Main threats and controls

| Threat | Control | Residual risk |
| --- | --- | --- |
| Mutable or substituted dependency | OCI chart and container image digests, fixed versions, Renovate review | Signature verification is not yet enforced at admission |
| Unreviewed cluster mutation | Pull-based Flux reconciliation and read-only CI permissions | A compromised Flux service account can change in-scope resources |
| Unsafe workload configuration | Restricted Pod Security Standards and enforced Kyverno rules | Controller namespaces are privileged trust zones |
| Bad release reaches all users | Incremental traffic shift, acceptance test, success/latency gates | Metrics can be incomplete or misleading during monitoring failure |
| Credential leakage | No secrets in the repository; cloud apply is manual | Operators must configure a secret manager and protected Terraform backend |
| Network lateral movement | Default-deny application policy with explicit ingress paths | kind's default CNI does not enforce NetworkPolicy locally |
| CI dependency compromise | GitHub Actions fixed to commit SHAs and restricted permissions | Transitive packages and downloaded chart contents still require review |

## Out of scope

- multi-region disaster recovery;
- application authentication and business data protection;
- a production secret-store installation;
- organization-specific identity and access management.

## Production follow-ups

1. Add Cilium or another NetworkPolicy-capable CNI.
2. Verify container signatures and attestations at admission.
3. Store Flux and application credentials in a managed secret store.
4. Send Alertmanager notifications to an owned on-call route.
5. Back Terraform state with encryption, locking, retention, and access logging.
