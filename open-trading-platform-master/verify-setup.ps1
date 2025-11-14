# Verification script for OTP prerequisites
Write-Host "Checking Open Trading Platform Prerequisites..." -ForegroundColor Cyan
Write-Host ""

# Check Docker
Write-Host "1. Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "   ✓ Docker installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Docker not found. Please install Docker Desktop." -ForegroundColor Red
}

# Check Kubernetes
Write-Host "`n2. Checking Kubernetes..." -ForegroundColor Yellow
try {
    $k8sVersion = kubectl version --client --short 2>$null
    Write-Host "   ✓ kubectl installed: $k8sVersion" -ForegroundColor Green
    
    $clusterInfo = kubectl cluster-info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Kubernetes cluster is running" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Kubernetes cluster not running. Enable it in Docker Desktop." -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ kubectl not found. Install Docker Desktop with Kubernetes." -ForegroundColor Red
}

# Check Helm
Write-Host "`n3. Checking Helm..." -ForegroundColor Yellow
try {
    $helmVersion = helm version --short
    Write-Host "   ✓ Helm installed: $helmVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Helm not found. Install with: choco install kubernetes-helm" -ForegroundColor Red
}

# Check Go
Write-Host "`n4. Checking Go..." -ForegroundColor Yellow
try {
    $goVersion = go version
    Write-Host "   ✓ Go installed: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Go not found" -ForegroundColor Red
}

# Check Maven
Write-Host "`n5. Checking Maven..." -ForegroundColor Yellow
try {
    $mvnVersion = mvn --version | Select-Object -First 1
    Write-Host "   ✓ Maven installed: $mvnVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Maven not found" -ForegroundColor Red
}

# Check Node.js
Write-Host "`n6. Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "   ✓ Node.js installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Node.js not found" -ForegroundColor Red
}

Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Status Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If all checks pass, you can install OTP with:" -ForegroundColor Yellow
Write-Host "  cd install" -ForegroundColor White
Write-Host "  ./install.sh -v 1.1.0" -ForegroundColor White
Write-Host ""
