# Quick status check for OTP on Scaleway

Write-Host "Open Trading Platform - Status Check" -ForegroundColor Cyan
Write-Host "====================================`n" -ForegroundColor Cyan

$kubectlPath = "$env:USERPROFILE\kubectl.exe"
$helmPath = "$env:USERPROFILE\helm.exe"

if (-not (Test-Path $kubectlPath)) {
    Write-Host "[ERROR] kubectl not found at $kubectlPath" -ForegroundColor Red
    exit 1
}

# Check cluster connection
Write-Host "Cluster Connection:" -ForegroundColor Yellow
& $kubectlPath cluster-info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Not connected to cluster" -ForegroundColor Red
    Write-Host "`nRun: .\complete-setup.ps1`n" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Connected`n" -ForegroundColor Green

# Check Helm releases
Write-Host "Helm Releases:" -ForegroundColor Yellow
& $helmPath list -A
Write-Host ""

# Check namespaces
Write-Host "Namespaces:" -ForegroundColor Yellow
& $kubectlPath get namespaces
Write-Host ""

# Check pods in all namespaces
Write-Host "Pods Status:" -ForegroundColor Yellow
& $kubectlPath get pods -A
Write-Host ""

# Check services
Write-Host "Services:" -ForegroundColor Yellow
& $kubectlPath get services -A
Write-Host ""

# Check for Envoy service specifically
Write-Host "Envoy Gateway (OTP Entry Point):" -ForegroundColor Cyan
$envoyService = & $kubectlPath get service envoy -n envoy -o json 2>$null | ConvertFrom-Json

if ($envoyService) {
    $externalIP = $envoyService.status.loadBalancer.ingress[0].ip
    $port = $envoyService.spec.ports[0].port
    
    if ($externalIP) {
        Write-Host "[OK] Envoy is accessible at: http://${externalIP}:${port}" -ForegroundColor Green
        Write-Host "`nAccess OTP Client:" -ForegroundColor Yellow
        Write-Host "  URL: http://${externalIP}:${port}" -ForegroundColor White
        Write-Host "  Users: trader1, trader2, support1, traderA, traderB, supportA" -ForegroundColor White
        Write-Host "  Password: (none required)`n" -ForegroundColor White
    } else {
        Write-Host "[WARNING] Envoy service found but no external IP yet (LoadBalancer provisioning...)" -ForegroundColor Yellow
        Write-Host "  Wait a few minutes and run this script again.`n" -ForegroundColor Gray
    }
} else {
    Write-Host "[ERROR] Envoy service not found. OTP may not be installed yet.`n" -ForegroundColor Red
}

# Check for any failing pods
Write-Host "Checking for issues..." -ForegroundColor Yellow
$failingPods = & $kubectlPath get pods -A -o json | ConvertFrom-Json | 
    Select-Object -ExpandProperty items | 
    Where-Object { $_.status.phase -ne "Running" -and $_.status.phase -ne "Succeeded" }

if ($failingPods) {
    Write-Host "[WARNING] Found pods with issues:" -ForegroundColor Yellow
    foreach ($pod in $failingPods) {
        Write-Host "  - $($pod.metadata.name) in $($pod.metadata.namespace): $($pod.status.phase)" -ForegroundColor Red
    }
    Write-Host "`nTo check logs: kubectl logs <pod-name> -n <namespace>`n" -ForegroundColor Gray
} else {
    Write-Host "[OK] All pods are healthy`n" -ForegroundColor Green
}
