# Simple Scaleway Cluster Creation Script

Write-Host "Creating Scaleway Kubernetes Cluster for OTP" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$clusterName = "otp-cluster"
$region = "fr-par"
$nodeType = "DEV1-M"
$nodeCount = 3
$poolName = "otp-pool"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Cluster Name: $clusterName" -ForegroundColor White
Write-Host "  Region: $region (Paris)" -ForegroundColor White
Write-Host "  Node Type: $nodeType (3 vCPU, 4GB RAM)" -ForegroundColor White
Write-Host "  Node Count: $nodeCount" -ForegroundColor White
Write-Host "  Estimated Cost: ~50 EUR/month (~55 USD/month)" -ForegroundColor Yellow
Write-Host "  Your Credit: 500 USD (lasts ~9 months!)`n" -ForegroundColor Green

Write-Host "Create cluster? (Y/N): " -ForegroundColor Cyan -NoNewline
$response = Read-Host

if ($response -ne 'Y' -and $response -ne 'y') {
    Write-Host "Cancelled.`n" -ForegroundColor Yellow
    exit 0
}

Write-Host "`nCreating cluster... This will take 5-10 minutes.`n" -ForegroundColor Yellow

scw k8s cluster create `
    name=$clusterName `
    region=$region `
    version=latest `
    cni=cilium `
    pools.0.name=$poolName `
    pools.0.node-type=$nodeType `
    pools.0.size=$nodeCount `
    pools.0.autoscaling=false

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Failed to create cluster" -ForegroundColor Red
    Write-Host "Check console: https://console.scaleway.com/kubernetes/clusters`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[OK] Cluster creation started!`n" -ForegroundColor Green

# Wait for cluster to be ready
Write-Host "Waiting for cluster to be ready..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0

do {
    Start-Sleep -Seconds 20
    $attempt++
    Write-Host "  Checking status... (attempt $attempt/$maxAttempts)" -ForegroundColor Gray
    
    $clusterStatus = scw k8s cluster get $clusterName region=$region -o json 2>$null | ConvertFrom-Json
    
    if ($clusterStatus.status -eq "ready") {
        Write-Host "`n[OK] Cluster is ready!`n" -ForegroundColor Green
        break
    }
    
    if ($attempt -ge $maxAttempts) {
        Write-Host "`n[WARNING] Cluster took too long. Check console:" -ForegroundColor Yellow
        Write-Host "  https://console.scaleway.com/kubernetes/clusters`n" -ForegroundColor Cyan
        exit 1
    }
} while ($true)

# Get kubeconfig
Write-Host "Getting cluster credentials..." -ForegroundColor Yellow
$clusterId = (scw k8s cluster list region=$region name=$clusterName -o json | ConvertFrom-Json)[0].id
scw k8s kubeconfig install $clusterId region=$region

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to get credentials`n" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Credentials configured`n" -ForegroundColor Green

# Verify connection
Write-Host "Verifying connection..." -ForegroundColor Yellow
$kubectlPath = "$env:USERPROFILE\kubectl.exe"
& $kubectlPath cluster-info

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Cluster Ready!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Next: Install OTP" -ForegroundColor Yellow
    Write-Host "  Run: .\open-trading-platform-master\complete-setup.ps1`n" -ForegroundColor White
} else {
    Write-Host "`n[ERROR] Cannot connect to cluster`n" -ForegroundColor Red
    exit 1
}
