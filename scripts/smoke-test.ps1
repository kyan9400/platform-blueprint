[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$expectedContext = "kind-platform-blueprint"
$currentContext = kubectl config current-context

if ($currentContext -ne $expectedContext) {
    throw "Refusing to test context $currentContext; expected $expectedContext"
}

$deployment = "podinfo-primary"
kubectl -n platform-demo get deployment $deployment *> $null
if ($LASTEXITCODE -ne 0) {
    $deployment = "podinfo"
}

kubectl -n platform-demo wait "deployment/$deployment" --for=condition=available --timeout=180s
if ($LASTEXITCODE -ne 0) { throw "Podinfo deployment is unavailable" }

$endpoint = ""
for ($attempt = 1; $attempt -le 36 -and -not $endpoint; $attempt++) {
    $endpoint = kubectl -n platform-demo get endpointslice `
        -l kubernetes.io/service-name=podinfo `
        -o jsonpath='{.items[0].endpoints[0].addresses[0]}' 2>$null
    if (-not $endpoint) { Start-Sleep -Seconds 5 }
}

if (-not $endpoint) { throw "Podinfo service has no ready endpoint" }

$loadtester = kubectl -n flagger-system get deployment `
    -l app.kubernetes.io/name=loadtester `
    -o jsonpath='{.items[0].metadata.name}'

if (-not $loadtester) { throw "Flagger load tester was not found" }

kubectl -n flagger-system exec "deployment/$loadtester" -- `
    curl --connect-timeout 5 --max-time 15 -fsS http://podinfo.platform-demo:9898/readyz
if ($LASTEXITCODE -ne 0) { throw "Podinfo readiness request failed" }

kubectl -n flagger-system exec "deployment/$loadtester" -- `
    curl --connect-timeout 5 --max-time 15 -fsS `
    -H "Host: podinfo.local" `
    http://ingress-nginx-controller.ingress-nginx/readyz
if ($LASTEXITCODE -ne 0) { throw "Podinfo ingress request failed" }

kubectl -n platform-demo get canary podinfo
Write-Output "smoke test passed"
