# Quick setup script for Open Trading Platform on Scaleway Kubernetes (Kapsule)

Write-Host "Open Trading Platform - Scaleway Kapsule Setup" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# Check if Scaleway CLI is installed
Write-Host "Checking for Scaleway CLI..." -ForegroundColor Yellow
try {
    $scwVersion = scw version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Scaleway CLI is installed`n" -ForegroundColor Green
    } else {
        throw "Not installed"
    }
} catch {
    Write-Host "✗ Scaleway CLI not found`n" -ForegroundColor Red
    Write-Host "Installing Scaleway CLI..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Download and install from:" -ForegroundColor White
    Write-Host "  https://github.com/scaleway/scaleway-cli/releases/latest`n" -ForegroundColor Cyan
    Write-Host "Or use PowerShell:" -ForegroundColor White
    Write-Host '  Invoke-WebRequest -Uri "https://github.com/scaleway/scaleway-cli/releases/latest/download/scaleway-cli_windows_amd64.exe" -OutFile "scw.exe"' -ForegroundColor Gray
    Write-Host '  Move-Item scw.exe C:\Windows\System32\scw.exe`n' -ForegroundColor Gray
    exit 1
}

# Check if kubectl is available
Write-Host "Checking for kubectl..." -ForegroundColor Yellow
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ kubectl is installed`n" -ForegroundColor Green
    } else {
        throw "Not installed"
    }
} catch {
    Write-Host "✗ kubectl not found" -ForegroundColor Red
    Write-Host "Install kubectl with: choco install kubernetes-cli`n" -ForegroundColor White
    exit 1
}

# Check if Helm is installed
Write-Host "Checking for Helm..." -ForegroundColor Yellow
try {
    $helmVersion = helm version --short 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Helm is installed`n" -ForegroundColor Green
    } else {
        throw "Not installed"
    }
} catch {
    Write-Host "✗ Helm not found`n" -ForegroundColor Red
    Write-Host "Install Helm with: choco install kubernetes-helm`n" -ForegroundColor White
    exit 1
}

# Configuration
$clusterName = "otp-cluster"
$region = "fr-par"  # Paris region (you can change to nl-ams, pl-waw)
$nodeType = "DEV1-M"  # 3 vCPU, 4GB RAM - good for dev/testing
$nodeCount = 3
$poolName = "otp-pool"

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Cluster Name: $clusterName" -ForegroundColor White
Write-Host "  Region: $region (Paris)" -ForegroundColor White
Write-Host "  Node Type: $nodeType (3 vCPU, 4GB RAM)" -ForegroundColor White
Write-Host "  Node Count: $nodeCount" -ForegroundColor White
Write-Host "  Estimated Cost: ~€50/month (~$55/month)" -ForegroundColor Yellow
Write-Host "  Your Credit: $500 USD (lasts ~9 months!)`n" -ForegroundColor Green

Write-Host "Scaleway Advantages:" -ForegroundColor Green
Write-Host "  • Very affordable pricing" -ForegroundColor White
Write-Host "  • Fast European infrastructure" -ForegroundColor White
Write-Host "  • Simple, straightforward setup" -ForegroundColor White
Write-Host "  • Your $500 credit covers months of usage`n" -ForegroundColor White

Write-Host "Available Regions:" -ForegroundColor Cyan
Write-Host "  fr-par (Paris, France) - Default" -ForegroundColor White
Write-Host "  nl-ams (Amsterdam, Netherlands)" -ForegroundColor White
Write-Host "  pl-waw (Warsaw, Poland)`n" -ForegroundColor White

Write-Host "Setup Steps:" -ForegroundColor Cyan
Write-Host "1. Initialize Scaleway CLI (configure API keys)" -ForegroundColor White
Write-Host "2. Create Kubernetes cluster (takes 5-10 minutes)" -ForegroundColor White
Write-Host "3. Get cluster credentials" -ForegroundColor White
Write-Host "4. Install Open Trading Platform`n" -ForegroundColor White

Write-Host "Ready to start? (Y/N): " -ForegroundColor Cyan -NoNewline
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "`nStarting Scaleway Kapsule setup...`n" -ForegroundColor Green
    
    # Step 1: Initialize Scaleway CLI
    Write-Host "Step 1: Initializing Scaleway CLI..." -ForegroundColor Yellow
    Write-Host "You'll need your Scaleway API credentials." -ForegroundColor Gray
    Write-Host "Get them from: https://console.scaleway.com/project/credentials`n" -ForegroundColor Cyan
    
    scw init
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n✗ Initialization failed. Please check your credentials." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n✓ Scaleway CLI initialized`n" -ForegroundColor Green
    
    # Step 2: Create Kubernetes cluster
    Write-Host "Step 2: Creating Kubernetes cluster '$clusterName'..." -ForegroundColor Yellow
    Write-Host "This will take 5-10 minutes. Please wait..." -ForegroundColor Gray
    Write-Host ""
    
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
        Write-Host "`n✗ Failed to create cluster." -ForegroundColor Red
        Write-Host "Check the Scaleway console for details: https://console.scaleway.com/kubernetes/clusters" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "`n✓ Cluster created successfully`n" -ForegroundColor Green
    
    # Wait for cluster to be ready
    Write-Host "Waiting for cluster to be ready..." -ForegroundColor Yellow
    $maxAttempts = 30
    $attempt = 0
    
    do {
        Start-Sleep -Seconds 10
        $attempt++
        Write-Host "  Checking cluster status... (attempt $attempt/$maxAttempts)" -ForegroundColor Gray
        
        $clusterStatus = scw k8s cluster get $clusterName region=$region -o json 2>$null | ConvertFrom-Json
        
        if ($clusterStatus.status -eq "ready") {
            break
        }
        
        if ($attempt -ge $maxAttempts) {
            Write-Host "`n✗ Cluster took too long to become ready." -ForegroundColor Red
            Write-Host "Check status in console: https://console.scaleway.com/kubernetes/clusters" -ForegroundColor Yellow
            exit 1
        }
    } while ($true)
    
    Write-Host "✓ Cluster is ready`n" -ForegroundColor Green
    
    # Step 3: Get kubeconfig
    Write-Host "Step 3: Getting cluster credentials..." -ForegroundColor Yellow
    
    # Get cluster ID
    $clusterId = (scw k8s cluster list region=$region name=$clusterName -o json | ConvertFrom-Json)[0].id
    
    # Download kubeconfig
    scw k8s kubeconfig install $clusterId region=$region
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n✗ Failed to get credentials." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Credentials configured`n" -ForegroundColor Green
    
    # Verify connection
    Write-Host "Verifying cluster connection..." -ForegroundColor Yellow
    kubectl cluster-info
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n✗ Cannot connect to cluster." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n✓ Successfully connected to Scaleway Kubernetes!`n" -ForegroundColor Green
    
    # Display cluster info
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Scaleway Kubernetes Cluster is Ready!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Cluster Details:" -ForegroundColor Cyan
    scw k8s cluster get $clusterName region=$region
    Write-Host ""
    
    Write-Host "Next: Install Open Trading Platform" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run these commands:" -ForegroundColor Yellow
    Write-Host "  cd install" -ForegroundColor White
    Write-Host "  bash install.sh -v 1.1.0" -ForegroundColor White
    Write-Host ""
    Write-Host "After installation, get the LoadBalancer IP:" -ForegroundColor Yellow
    Write-Host "  kubectl get services -n default" -ForegroundColor White
    Write-Host ""
    Write-Host "Access the client at: http://<EXTERNAL-IP>:port" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Cluster Management Commands:" -ForegroundColor Cyan
    Write-Host "  View cluster: scw k8s cluster get $clusterName region=$region" -ForegroundColor Gray
    Write-Host "  List nodes: kubectl get nodes" -ForegroundColor Gray
    Write-Host "  Scale pool: scw k8s pool update <pool-id> size=<new-size> region=$region" -ForegroundColor Gray
    Write-Host "  Delete cluster: scw k8s cluster delete $clusterName region=$region" -ForegroundColor Gray
    Write-Host "  Console: https://console.scaleway.com/kubernetes/clusters" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Cost Tracking:" -ForegroundColor Cyan
    Write-Host "  View billing: https://console.scaleway.com/billing/consumption" -ForegroundColor Gray
    Write-Host "  Current rate: ~€50/month (~$55/month)" -ForegroundColor Gray
    Write-Host "  Your credit: $500 USD (covers ~9 months)" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Install OTP now? (Y/N): " -ForegroundColor Cyan -NoNewline
    $installNow = Read-Host
    
    if ($installNow -eq 'Y' -or $installNow -eq 'y') {
        Write-Host "`nInstalling Open Trading Platform...`n" -ForegroundColor Green
        Set-Location install
        bash install.sh -v 1.1.0
    } else {
        Write-Host "`nSetup complete! Install OTP when ready with:" -ForegroundColor Yellow
        Write-Host "  cd install" -ForegroundColor White
        Write-Host "  bash install.sh -v 1.1.0" -ForegroundColor White
    }
    
} else {
    Write-Host "`nSetup cancelled.`n" -ForegroundColor Yellow
    Write-Host "Manual setup commands:" -ForegroundColor Cyan
    Write-Host "  scw init" -ForegroundColor White
    Write-Host "  scw k8s cluster create name=$clusterName region=$region version=latest cni=cilium pools.0.name=$poolName pools.0.node-type=$nodeType pools.0.size=$nodeCount" -ForegroundColor White
    Write-Host "  scw k8s kubeconfig install <cluster-id> region=$region" -ForegroundColor White
    Write-Host "  cd install" -ForegroundColor White
    Write-Host "  bash install.sh -v 1.1.0`n" -ForegroundColor White
}
