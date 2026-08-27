[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$cluster = "platform-blueprint"

foreach ($tool in @("docker", "kind", "kubectl", "flux")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool is required"
    }
}

$clusters = kind get clusters
if ($clusters -notcontains $cluster) {
    kind create cluster --name $cluster --config clusters/local/kind.yaml
    if ($LASTEXITCODE -ne 0) { throw "kind cluster creation failed" }
}

$currentContext = kubectl config current-context
if ($currentContext -ne "kind-$cluster") {
    throw "Refusing to continue on context $currentContext"
}

flux install --version=v2.9.4
if ($LASTEXITCODE -ne 0) { throw "Flux installation failed" }

kubectl apply -k clusters/local
if ($LASTEXITCODE -ne 0) { throw "Cluster reconciliation root failed" }

kubectl -n flux-system wait gitrepository/platform-blueprint --for=condition=ready --timeout=180s
if ($LASTEXITCODE -ne 0) { throw "Git source did not become ready" }

flux reconcile kustomization platform-controllers --with-source --timeout=15m
flux reconcile kustomization policy-guardrails --timeout=5m
flux reconcile kustomization observability --timeout=5m
flux reconcile kustomization demo-workload --timeout=10m

flux get kustomizations
Write-Output "Platform ready. Run ./scripts/smoke-test.ps1"
