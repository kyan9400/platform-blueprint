[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$cluster = "platform-blueprint"
$clusters = kind get clusters

if ($clusters -contains $cluster) {
    kind delete cluster --name $cluster
    if ($LASTEXITCODE -ne 0) { throw "Failed to delete cluster $cluster" }
} else {
    Write-Output "cluster $cluster does not exist"
}
