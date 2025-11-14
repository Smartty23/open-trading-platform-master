# Quick setup script for Open Trading Platform on Azure Kubernetes Service (AKS)

Write-Host "Open Trading Platform - Azure AKS Setup" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

# Check if Azure CLI is installed
Write-Host "Checking for Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = az version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Azure CLI is installed`n" -ForegroundColor Green
    } else {
        throw "Not installed"
    }
} catch {
    Write-Host "✗ Azure CLI not found`n" -ForegroundColor Red
    Write-Host "Installing Azure CLI..." -ForegroundColor Yellow
    Write-Host "Run: choco install azure-cli`n" -ForegroundColor White
    Write-Host "Or download from: https://aka.ms/installazurecliwindows`n" -ForegroundColor White
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
    Write-Host "Installing kubectl..." -ForegroundColor Yellow
    az aks install-cli
    Write-Host ""
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
$resourceGroup = "otp-rg"
$clusterName = "otp-cluster"
$location = "eastus"
$nodeCount = 3
$nodeSize = "Standard_D2s_v3"  # 2 vCPU, 8GB RAM

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Resource Group: $resourceGroup" -ForegroundColor White
Write-Host "  Cluster Name: $clusterName" -ForegroundColor White
Write-Host "  Location: $location" -ForegroundColor White
Write-Host "  Node Count: $nodeCount" -ForegroundColor White
Write-Host "  Node Size: $nodeSize (2 vCPU, 8GB RAM)" -ForegroundColor White
Write-Host "  Estimated Cost: ~$150/month`n" -ForegroundColor Yellow

Write-Host "Azure Free Tier includes:" -ForegroundColor Green
Write-Host "  • $200 credit for 30 days (new accounts)" -ForegroundColor White
Write-Host "  • Free AKS control plane" -ForegroundColor White
Write-Host "  • Pay only for worker nodes`n" -ForegroundColor White

Write-Host "Setup Steps:" -ForegroundColor Cyan
Write-Host "1. Login to Azure" -ForegroundColor White
Write-Host "2. Create resource group" -ForegroundColor White
Write-Host "3. Create AKS cluster (takes 5-10 minutes)" -ForegroundColor White
Write-Host "4. Get cluster credentials" -ForegroundColor White
Write-Host "5. Install Open Trading Platform`n" -ForegroundColor White

Write-Host "Ready to start? (Y/N): " -ForegroundColor Cyan -NoNewline
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "`nStarting Azure AKS setup...`n" -ForegroundColor Green
    
    # Step 1: Login
    Write-Host "Step 1: Logging in to Azure..." -ForegroundColor Yellow
    Write-Host "A browser window will open for authentication..." -ForegroundColor Gray
    az login
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n✗ Login failed. Please try again." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Login successful`n" -ForegroundColor Green
    
    # Step 2: Create resource group
    Write-Host "Step 2: Creating resource group '$resourceGroup'..." -ForegroundColor Yellow
    az group create --name $resourceGroup --location $location
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n✗ Failed to create resource group." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Resource group created`n" -ForegroundColor Green
    
    # Step 3: Create AKS cluster
    Write-Host "Step 3: Creating AKS cluster '$clusterName'..." -ForegroundColor Yellow
    Write-Host "This will take 5-10 minutes. Please wait..." -ForegroundColor Gray
    Write-Host ""
    
    az aks create `
        --resource-group $resourceGroup `
        --name $clusterName `
        --node-count $nodeCount `
        --node-vm-size $nodeSize `
        --enable-addons monitoring `
        --generate-ssh-keys `
        --network-plugin azure `
        --load-balancer-sku standard
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n✗ Failed to create AKS cluster." -ForegroundColor Red
        Write-Host "You can check the Azure Portal for more details." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "`n✓ AKS cluster created successfully`n" -ForegroundColor Green
    
    # Step 4: Get credentials
    Write-Host "Step 4: Getting cluster credentials..." -ForegroundColor Yellow
    az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing
    
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
    
    Write-Host "`n✓ Successfully connected to AKS cluster!`n" -ForegroundColor Green
    
    # Step 5: Install OTP
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "AKS Cluster is Ready!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Next: Install Open Trading Platform" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run these commands:" -ForegroundColor Yellow
    Write-Host "  cd install" -ForegroundColor White
    Write-Host "  bash install.sh -v 1.1.0" -ForegroundColor White
    Write-Host ""
    Write-Host "After installation completes, get the client URL with:" -ForegroundColor Yellow
    Write-Host "  kubectl get services -n default" -ForegroundColor White
    Write-Host ""
    Write-Host "To access from your browser, you may need to set up port forwarding:" -ForegroundColor Yellow
    Write-Host "  kubectl port-forward svc/opentp-client 8080:80 -n default" -ForegroundColor White
    Write-Host "  Then open: http://localhost:8080" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Cluster Management Commands:" -ForegroundColor Cyan
    Write-Host "  View cluster: az aks show --resource-group $resourceGroup --name $clusterName" -ForegroundColor Gray
    Write-Host "  Stop cluster: az aks stop --resource-group $resourceGroup --name $clusterName" -ForegroundColor Gray
    Write-Host "  Start cluster: az aks start --resource-group $resourceGroup --name $clusterName" -ForegroundColor Gray
    Write-Host "  Delete cluster: az aks delete --resource-group $resourceGroup --name $clusterName" -ForegroundColor Gray
    Write-Host "  Delete resource group: az group delete --name $resourceGroup --yes" -ForegroundColor Gray
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
    Write-Host "  az login" -ForegroundColor White
    Write-Host "  az group create --name $resourceGroup --location $location" -ForegroundColor White
    Write-Host "  az aks create --resource-group $resourceGroup --name $clusterName --node-count $nodeCount --node-vm-size $nodeSize --enable-addons monitoring --generate-ssh-keys" -ForegroundColor White
    Write-Host "  az aks get-credentials --resource-group $resourceGroup --name $clusterName" -ForegroundColor White
    Write-Host "  cd install" -ForegroundColor White
    Write-Host "  bash install.sh -v 1.1.0`n" -ForegroundColor White
}
