# AWS EKS infrastructure

This root module provisions a three-AZ VPC, private worker subnets, public load-balancer subnets, and an EKS managed node group. The Kubernetes API is private by default.

## Safety properties

- `terraform apply` is never run by repository CI.
- No credentials or state are committed.
- Provider and module versions are constrained.
- Production can use one NAT gateway per availability zone.
- Node counts are checked before planning.

## Validate

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

## Plan

Create an encrypted, locked remote state backend, then:

```bash
cp backend.hcl.example backend.hcl
cp staging.tfvars.example staging.tfvars
terraform init -backend-config=backend.hcl
terraform plan -var-file=staging.tfvars -out=staging.tfplan
terraform show staging.tfplan
```

Do not apply until the plan has been reviewed, cost impact is understood, and cluster access paths are ready. A private endpoint requires network connectivity from the operator or deployment runner.

## Bootstrap after approval

After provisioning, configure `kubectl`, install Flux, and apply the appropriate cluster reconciliation root. Cloud-specific DNS, TLS, external secrets, and notification receivers should be added before production traffic.

## Destroy

Destroy application load balancers before the cluster and VPC to avoid orphaned AWS resources. Preserve the plan and obtain the same approval required for creation:

```bash
terraform plan -destroy -var-file=staging.tfvars -out=destroy.tfplan
terraform show destroy.tfplan
terraform apply destroy.tfplan
```
