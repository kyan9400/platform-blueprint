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

$forwardLog = Join-Path ([System.IO.Path]::GetTempPath()) "platform-blueprint-port-forward.log"
$forward = Start-Process kubectl -WindowStyle Hidden -PassThru -RedirectStandardOutput $forwardLog `
    -RedirectStandardError "$forwardLog.err" `
    -ArgumentList "-n", "platform-demo", "port-forward", "service/podinfo", "18080:9898"

try {
    $serviceReady = $false
    for ($attempt = 1; $attempt -le 30 -and -not $serviceReady; $attempt++) {
        try {
            Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 `
                -Uri http://127.0.0.1:18080/readyz *> $null
            $serviceReady = $true
        }
        catch {
            Start-Sleep -Seconds 2
        }
    }

    if (-not $serviceReady) { throw "Podinfo service did not answer through kubectl port-forward" }

    $headers = @{ Host = "podinfo.local" }
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 10 -Headers $headers `
        -Uri http://127.0.0.1/readyz *> $null
}
finally {
    if (-not $forward.HasExited) { Stop-Process -Id $forward.Id }
    Remove-Item -LiteralPath $forwardLog, "$forwardLog.err" -Force -ErrorAction SilentlyContinue
}

kubectl -n platform-demo get canary podinfo
Write-Output "smoke test passed"
