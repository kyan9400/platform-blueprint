[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl is required"
}

$paths = @(
    "clusters/local",
    "infrastructure/controllers",
    "policies",
    "observability",
    "apps/podinfo/overlays/local",
    "apps/podinfo/overlays/staging",
    "apps/podinfo/overlays/production"
)

foreach ($path in $paths) {
    $rendered = kubectl kustomize $path
    if ($LASTEXITCODE -ne 0 -or -not $rendered) {
        throw "Failed to render $path"
    }

    $manifest = $rendered -join "`n"
    if ($manifest -match '(?m)^\s*image:\s+\S+:latest(?:\s|$)') {
        throw "Mutable workload image in $path"
    }
    if ($manifest -match '(?m)^kind:\s+Secret$') {
        throw "Plain Kubernetes Secret found in $path"
    }

    Write-Output "rendered $path"
}

Write-Output "manifest verification passed"
