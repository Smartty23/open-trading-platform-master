# Connect to Manually Created Scaleway Cluster

Write-Host "Connect to Scaleway Kubernetes Cluster" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# List available clusters
Write-Host "Fetching your Scaleway clusters...`n" -ForegroundColor Yellow
$clusters = scw k8s cluster list -o json 2>$null | ConvertFrom-Json

if (-not $clusters -or $clusters.Count -eq 0) {
    Write-Host "[ERROR] No clusters found in your Scaleway account" -ForegroundColor Red
    Write-Host "`nOptions:" -ForegroundColor Yellow
    Write-Host "1. Create a cluster manually in the console:" -ForegroundColor White
    Write-Host "   https://console.scaleway.com/kubernetes/clusters" -ForegroundColor Cyan
    Write-Host "2. Or run the automated script (if quota allows):" -ForegroundColor White
    Write-Host "   .\open-trading-platform-master\create-cluster.ps1`n" -ForegroundColor Cyan
    exit 1
}

Write-Host "Available Clusters:" -ForegroundColor Cyan
Write-Host "==================`n" -ForegroundColor Cyan

for ($i = 0; $i -lt $clusters.Count; $i++) {
    $cluster = $clusters[$i]
    Write-Host "[$i] Name: $($cluster.name)" -ForegroundColor White
    Write-Host "    ID: $($cluster.id)" -ForegroundColor Gray
    Write-Host "    Region: $($cluster.region)" -ForegroundColor Gray
    Write-Host "    Status: $($cluster.status)" -ForegroundColor $(if ($cluster.status -eq "ready") { "Green" } else { "Yellow" })
    Write-Host "    Version: $($cluster.version)" -ForegroundColor Gray
    Write-Host "    Created: $($cluster.created_at)" -ForegroundColor Gray
    Write-Host ""
}

# Select cluster
if ($clusters.Count -eq 1) {
    $selectedIndex = 0
    Write-Host "Using cluster: $($clusters[0].name)`n" -ForegroundColor Green
} else {
    Write-Host "Select cluster (0-$($clusters.Count - 1)): " -ForegroundColor Yellow -NoNewline
    $selectedIndex = [int](Read-Host)
    
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $clusters.Count) {
        Write-Host "[ERROR] Invalid selection`n" -ForegroundColor Red
        exit 1
    }
}

$selectedCluster = $clusters[$selectedIndex]

# Check if cluster is ready
if ($selectedCluster.status -ne "ready") {
    Write-Host "[WARNING] Cluster status is: $($selectedCluster.status)" -ForegroundColor Yellow
    Write-Host "The cluster may not be fully ready yet.`n" -ForegroundColor Yellow
    Write-Host "Continue anyway? (Y/N): " -ForegroundColor Yellow -NoNewline
    $continue = Read-Host
    
    if ($continue -ne 'Y' -and $continue -ne 'y') {
        Write-Host "Cancelled. Wait for cluster to be ready and try again.`n" -ForegroundColor Yellow
        exit 0
    }
}

# Install kubeconfig
Write-Host "`nConnecting to cluster: $($selectedCluster.name)..." -ForegroundColor Yellow
Write-Host "  ID: $($selectedCluster.id)" -ForegroundColor Gray
Write-Host "  Region: $($selectedCluster.region)`n" -ForegroundColor Gray

scw k8s kubeconfig install $selectedCluster.id region=$selectedCluster.region

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to install kubeconfig`n" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Kubeconfig installed`n" -ForegroundColor Green

# Verify connection
Write-Host "Verifying connection..." -ForegroundColor Yellow
$kubectlPath = "$env:USERPROFILE\kubectl.exe"

if (-not (Test-Path $kubectlPath)) {
    $kubectlPath = "kubectl"
}

Write-Host "`nCluster Info:" -ForegroundColor Cyan
& $kubectlPath cluster-info

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Cannot connect to cluster" -ForegroundColor Red
    Write-Host "Try running: kubectl config get-contexts`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nNodes:" -ForegroundColor Cyan
& $kubectlPath get nodes

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Connected Successfully!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if OTP is installed
Write-Host "Checking for OTP installation..." -ForegroundColor Yellow
$helmPath = "$env:USERPROFILE\helm.exe"
if (-not (Test-Path $helmPath)) {
    $helmPath = "helm"
}

$otpInstalled = & $helmPath list -A -o json 2>$null | ConvertFrom-Json | Where-Object { $_.name -like "otp-*" -or $_.name -like "*kafka*" -or $_.name -like "*postgresql*" }

if ($otpInstalled) {
    Write-Host "[OK] OTP appears to be installed`n" -ForegroundColor Green
    Write-Host "Check status with:" -ForegroundColor Yellow
    Write-Host "  .\open-trading-platform-master\check-status.ps1`n" -ForegroundColor White
} else {
    Write-Host "[INFO] OTP not installed yet`n" -ForegroundColor Yellow
    Write-Host "Install OTP? (Y/N): " -ForegroundColor Cyan -NoNewline
    $install = Read-Host
    
    if ($install -eq 'Y' -or $install -eq 'y') {
        Write-Host "`nDo you have Git Bash installed? (Y/N): " -ForegroundColor Yellow -NoNewline
        $hasBash = Read-Host
        
        if ($hasBash -eq 'Y' -or $hasBash -eq 'y') {
            Write-Host "`nInstalling OTP... This will take 10-15 minutes`n" -ForegroundColor Green
            Set-Location "$PSScriptRoot"
            bash install/install.sh -v 1.1.0
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n[OK] Installation complete!`n" -ForegroundColor Green
                Write-Host "Check status with:" -ForegroundColor Yellow
                Write-Host "  .\open-trading-platform-master\check-status.ps1`n" -ForegroundColor White
            }
        } else {
            Write-Host "`nInstall Git Bash first:" -ForegroundColor Yellow
            Write-Host "  https://git-scm.com/download/win" -ForegroundColor Cyan
            Write-Host "`nThen run:" -ForegroundColor Yellow
            Write-Host "  cd open-trading-platform-master\install" -ForegroundColor White
            Write-Host "  bash install.sh -v 1.1.0`n" -ForegroundColor White
        }
    } else {
        Write-Host "`nTo install OTP later, run:" -ForegroundColor Yellow
        Write-Host "  cd open-trading-platform-master\install" -ForegroundColor White
        Write-Host "  bash install.sh -v 1.1.0`n" -ForegroundColor White
    }
}

Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -A              # Check all pods" -ForegroundColor Gray
Write-Host "  kubectl get services -A          # Check all services" -ForegroundColor Gray
Write-Host "  kubectl get nodes                # Check cluster nodes" -ForegroundColor Gray
Write-Host "  helm list -A                     # List helm releases`n" -ForegroundColor Gray
