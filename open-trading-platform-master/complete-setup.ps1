# Complete OTP Setup for Scaleway
# This script will:
# 1. Add kubectl and helm to PATH
# 2. Initialize Scaleway CLI
# 3. Connect to your cluster
# 4. Install OTP using Helm

Write-Host "Open Trading Platform - Complete Setup" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Step 1: Add kubectl and helm to PATH for this session
Write-Host "Step 1: Setting up kubectl and helm..." -ForegroundColor Yellow
$kubectlPath = "$env:USERPROFILE\kubectl.exe"
$helmPath = "$env:USERPROFILE\helm.exe"

if (Test-Path $kubectlPath) {
    Write-Host "  [OK] kubectl found at $kubectlPath" -ForegroundColor Green
    $env:PATH = "$env:USERPROFILE;$env:PATH"
} else {
    Write-Host "  [ERROR] kubectl not found at $kubectlPath" -ForegroundColor Red
    exit 1
}

if (Test-Path $helmPath) {
    Write-Host "  [OK] helm found at $helmPath" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] helm not found at $helmPath" -ForegroundColor Red
    exit 1
}

# Verify they work
Write-Host "`nVerifying kubectl..." -ForegroundColor Yellow
& $kubectlPath version --client 2>$null | Select-Object -First 1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERROR] kubectl verification failed" -ForegroundColor Red
    exit 1
}

Write-Host "`nVerifying helm..." -ForegroundColor Yellow
& $helmPath version 2>$null | Select-Object -First 1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERROR] helm verification failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n[OK] Tools verified`n" -ForegroundColor Green

# Step 2: Check Scaleway CLI
Write-Host "Step 2: Checking Scaleway CLI..." -ForegroundColor Yellow
try {
    $scwVersion = scw version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Scaleway CLI is installed" -ForegroundColor Green
    } else {
        throw "Not installed"
    }
} catch {
    Write-Host "  [ERROR] Scaleway CLI not found" -ForegroundColor Red
    Write-Host "`nPlease install Scaleway CLI first:" -ForegroundColor Yellow
    Write-Host "  https://github.com/scaleway/scaleway-cli/releases/latest`n" -ForegroundColor Cyan
    exit 1
}

# Step 3: Initialize Scaleway (if needed)
Write-Host "`nStep 3: Checking Scaleway configuration..." -ForegroundColor Yellow
$scwConfig = scw config get access-key 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($scwConfig)) {
    Write-Host "  Scaleway CLI needs to be initialized" -ForegroundColor Yellow
    Write-Host "`n  Get your API credentials from:" -ForegroundColor Cyan
    Write-Host "  https://console.scaleway.com/project/credentials`n" -ForegroundColor Cyan
    
    Write-Host "  Initialize now? (Y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    
    if ($response -eq 'Y' -or $response -eq 'y') {
        scw init
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n  [ERROR] Initialization failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "`n  Setup cancelled. Run 'scw init' manually and try again." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "  [OK] Scaleway CLI is configured" -ForegroundColor Green
}

# Step 4: List clusters and connect
Write-Host "`nStep 4: Checking for Scaleway Kubernetes clusters..." -ForegroundColor Yellow
$clusters = scw k8s cluster list -o json 2>$null | ConvertFrom-Json

if ($clusters.Count -eq 0) {
    Write-Host "  No clusters found. Would you like to create one? (Y/N): " -ForegroundColor Yellow -NoNewline
    $createCluster = Read-Host
    
    if ($createCluster -eq 'Y' -or $createCluster -eq 'y') {
        Write-Host "`n  Running cluster creation script..." -ForegroundColor Green
        & "$PSScriptRoot\setup-scaleway.ps1"
        exit 0
    } else {
        Write-Host "`n  No cluster available. Run setup-scaleway.ps1 to create one." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`n  Available clusters:" -ForegroundColor Cyan
for ($i = 0; $i -lt $clusters.Count; $i++) {
    $cluster = $clusters[$i]
    Write-Host "    [$i] $($cluster.name) - $($cluster.region) - Status: $($cluster.status)" -ForegroundColor White
}

if ($clusters.Count -eq 1) {
    $selectedIndex = 0
    Write-Host "`n  Using cluster: $($clusters[0].name)" -ForegroundColor Green
} else {
    Write-Host "`n  Select cluster (0-$($clusters.Count - 1)): " -ForegroundColor Yellow -NoNewline
    $selectedIndex = [int](Read-Host)
}

$selectedCluster = $clusters[$selectedIndex]
Write-Host "`n  Connecting to cluster: $($selectedCluster.name)..." -ForegroundColor Yellow

# Install kubeconfig
scw k8s kubeconfig install $selectedCluster.id region=$selectedCluster.region
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERROR] Failed to get cluster credentials" -ForegroundColor Red
    exit 1
}

Write-Host "  [OK] Connected to cluster`n" -ForegroundColor Green

# Verify connection
Write-Host "  Verifying cluster connection..." -ForegroundColor Yellow
& $kubectlPath cluster-info
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n  [ERROR] Cannot connect to cluster" -ForegroundColor Red
    exit 1
}

Write-Host "`n  [OK] Cluster connection verified`n" -ForegroundColor Green

# Step 5: Check if OTP is already installed
Write-Host "Step 5: Checking for existing OTP installation..." -ForegroundColor Yellow
$existingOtp = & $helmPath list -A -o json 2>$null | ConvertFrom-Json | Where-Object { $_.name -like "otp-*" }

if ($existingOtp) {
    Write-Host "  Found existing OTP installation: $($existingOtp.name)" -ForegroundColor Yellow
    Write-Host "  Status: $($existingOtp.status)" -ForegroundColor White
    Write-Host "`n  Reinstall? (Y/N): " -ForegroundColor Yellow -NoNewline
    $reinstall = Read-Host
    
    if ($reinstall -ne 'Y' -and $reinstall -ne 'y') {
        Write-Host "`n  Skipping installation. Checking services..." -ForegroundColor Yellow
        & $kubectlPath get services -A
        Write-Host "`n  To access OTP, find the envoy service external IP above." -ForegroundColor Cyan
        exit 0
    }
}

# Step 6: Install OTP
Write-Host "`nStep 6: Installing Open Trading Platform..." -ForegroundColor Yellow
Write-Host "  This will take 10-15 minutes. Installing:" -ForegroundColor Gray
Write-Host "    - Kafka (message broker)" -ForegroundColor Gray
Write-Host "    - PostgreSQL (database)" -ForegroundColor Gray
Write-Host "    - Envoy (API gateway)" -ForegroundColor Gray
Write-Host "    - OTP services (trading platform)`n" -ForegroundColor Gray

Write-Host "  Do you have Git Bash or WSL installed? (Y/N): " -ForegroundColor Yellow -NoNewline
$hasBash = Read-Host

if ($hasBash -eq 'Y' -or $hasBash -eq 'y') {
    Write-Host "`n  Running install script..." -ForegroundColor Green
    Write-Host "  Command: bash install/install.sh -v 1.1.0`n" -ForegroundColor Gray
    
    Set-Location "$PSScriptRoot"
    bash install/install.sh -v 1.1.0
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[OK] Installation complete!`n" -ForegroundColor Green
    } else {
        Write-Host "`n[ERROR] Installation failed. Check the errors above.`n" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n  You need Git Bash or WSL to run the install script." -ForegroundColor Red
    Write-Host "`n  Options:" -ForegroundColor Yellow
    Write-Host "    1. Install Git for Windows (includes Git Bash):" -ForegroundColor White
    Write-Host "       https://git-scm.com/download/win" -ForegroundColor Cyan
    Write-Host "    2. Install WSL:" -ForegroundColor White
    Write-Host "       wsl --install" -ForegroundColor Cyan
    Write-Host "`n  After installing, run this script again.`n" -ForegroundColor Yellow
    exit 1
}

# Step 7: Get access information
Write-Host "`nStep 7: Getting access information..." -ForegroundColor Yellow
Write-Host "`n  Services:" -ForegroundColor Cyan
& $kubectlPath get services -A

Write-Host "`n  Pods:" -ForegroundColor Cyan
& $kubectlPath get pods -A

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait for all pods to be Running (check with: kubectl get pods -A)" -ForegroundColor White
Write-Host "2. Get the Envoy service external IP:" -ForegroundColor White
Write-Host "   kubectl get service envoy -n envoy" -ForegroundColor Gray
Write-Host "3. Access OTP at: http://<EXTERNAL-IP>:<PORT>" -ForegroundColor White
Write-Host "4. Login with any of these users (no password needed):" -ForegroundColor White
Write-Host "   - trader1, trader2 (Desk1 traders)" -ForegroundColor Gray
Write-Host "   - support1 (Desk1 view-only)" -ForegroundColor Gray
Write-Host "   - traderA, traderB (DeskA traders)" -ForegroundColor Gray
Write-Host "   - supportA (DeskA view-only)`n" -ForegroundColor Gray

Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -A              # Check all pods" -ForegroundColor Gray
Write-Host "  kubectl get services -A          # Check all services" -ForegroundColor Gray
Write-Host "  kubectl logs <pod-name> -n <ns>  # View pod logs" -ForegroundColor Gray
Write-Host "  helm list -A                     # List helm releases`n" -ForegroundColor Gray
