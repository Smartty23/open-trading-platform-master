# Quick setup script for Open Trading Platform on Google Kubernetes Engine (GKE)

Write-Host "Open Trading Platform - GKE Setup" -ForegroundColor Cyan
Write-Host "====================================`n" -ForegroundColor Cyan

# Check if gcloud is installed
Write-Host "Checking for Google Cloud SDK..." -ForegroundColor Yellow
try {
    $gcloudVersion = gcloud version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Google Cloud SDK is installed`n" -ForegroundColor Green
    } else {
        throw "Not installed"
    }
} catch {
    Write-Host "✗ Google Cloud SDK not found`n" -ForegroundColor Red
    Write-Host "Installing Google Cloud SDK..." -ForegroundColor Yellow
    Write-Host "Run: choco install gcloudsdk`n" -ForegroundColor White
    Write-Host "Or download from: https://cloud.google.com/sdk/docs/install`n" -ForegroundColor White
    exit 1
}

# Project setup
$projectId = "otp-demo-" + (Get-Random -Maximum 9999)
Write-Host "Setting up GKE cluster..." -ForegroundColor Yellow
Write-Host "Project ID: $projectId`n" -ForegroundColor White

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Login to Google Cloud:" -ForegroundColor White
Write-Host "   gcloud auth login`n" -ForegroundColor Gray

Write-Host "2. Create and configure project:" -ForegroundColor White
Write-Host "   gcloud projects create $projectId --name='Open Trading Platform'" -ForegroundColor Gray
Write-Host "   gcloud config set project $projectId" -ForegroundColor Gray
Write-Host "   gcloud services enable container.googleapis.com`n" -ForegroundColor Gray

Write-Host "3. Create Kubernetes cluster (takes 5-10 minutes):" -ForegroundColor White
Write-Host "   gcloud container clusters create otp-cluster --zone=us-central1-a --num-nodes=3 --machine-type=e2-standard-2`n" -ForegroundColor Gray

Write-Host "4. Get cluster credentials:" -ForegroundColor White
Write-Host "   gcloud container clusters get-credentials otp-cluster --zone=us-central1-a`n" -ForegroundColor Gray

Write-Host "5. Install Helm (if not installed):" -ForegroundColor White
Write-Host "   choco install kubernetes-helm`n" -ForegroundColor Gray

Write-Host "6. Install Open Trading Platform:" -ForegroundColor White
Write-Host "   cd install" -ForegroundColor Gray
Write-Host "   bash install.sh -v 1.1.0`n" -ForegroundColor Gray

Write-Host "7. Get the client URL:" -ForegroundColor White
Write-Host "   kubectl get services -n default | findstr opentp-client`n" -ForegroundColor Gray

Write-Host "`nEstimated cost: ~$100/month (covered by $300 free credit)" -ForegroundColor Yellow
Write-Host "Free credit lasts 90 days or until $300 is used`n" -ForegroundColor Yellow

Write-Host "Ready to start? (Y/N): " -ForegroundColor Cyan -NoNewline
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "`nStarting setup...`n" -ForegroundColor Green
    
    Write-Host "Step 1: Logging in to Google Cloud..." -ForegroundColor Yellow
    gcloud auth login
    
    Write-Host "`nStep 2: Creating project..." -ForegroundColor Yellow
    gcloud projects create $projectId --name="Open Trading Platform"
    gcloud config set project $projectId
    
    Write-Host "`nStep 3: Enabling Kubernetes API..." -ForegroundColor Yellow
    gcloud services enable container.googleapis.com
    
    Write-Host "`nStep 4: Creating Kubernetes cluster (this takes 5-10 minutes)..." -ForegroundColor Yellow
    gcloud container clusters create otp-cluster --zone=us-central1-a --num-nodes=3 --machine-type=e2-standard-2
    
    Write-Host "`nStep 5: Getting cluster credentials..." -ForegroundColor Yellow
    gcloud container clusters get-credentials otp-cluster --zone=us-central1-a
    
    Write-Host "`n✓ GKE cluster is ready!" -ForegroundColor Green
    Write-Host "`nNow run:" -ForegroundColor Cyan
    Write-Host "  cd install" -ForegroundColor White
    Write-Host "  bash install.sh -v 1.1.0" -ForegroundColor White
} else {
    Write-Host "`nSetup cancelled. Run this script again when ready." -ForegroundColor Yellow
}
