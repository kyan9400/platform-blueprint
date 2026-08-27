# Architecture decisions

## ADR-001: Consume the workload instead of copying it

**Decision:** Reference Podinfo through its OCI Helm artifact and retain upstream attribution.

**Why:** The portfolio value is the platform behavior. Copying an established application would blur authorship, make upstream fixes harder to receive, and create an unnecessary maintenance fork.

**Consequence:** Application changes belong upstream. This repository changes deployment, policy, release, and operations behavior.

## ADR-002: Flux for pull-based reconciliation

**Decision:** Use Flux rather than a CI job with cluster credentials.

**Why:** Pull-based reconciliation keeps long-lived cluster credentials out of GitHub Actions and continuously corrects drift.

**Consequence:** A cluster must bootstrap Flux once. Normal changes then flow through Git.

## ADR-003: Flagger and NGINX for progressive delivery

**Decision:** Use metric-gated canaries rather than plain rolling updates.

**Why:** The workload exposes fault injection and Prometheus telemetry, which makes release decisions observable and reproducible.

**Consequence:** NGINX and Prometheus become rollout dependencies and need their own health checks.

## ADR-004: Local-first, cloud-ready

**Decision:** Make the full workflow reproducible on kind and provide EKS as a separately reviewed Terraform path.

**Why:** Reviewers can verify the platform without a cloud account, while the infrastructure module demonstrates a realistic production target.

**Consequence:** CI validates but never applies cloud infrastructure.

## ADR-005: Enforce workload controls at admission

**Decision:** Use Kyverno rules scoped to `platform-*` namespaces plus Kubernetes Pod Security Standards.

**Why:** Repository conventions can be bypassed; admission controls make the contract executable.

**Consequence:** exceptions require an explicit policy change and code review.
