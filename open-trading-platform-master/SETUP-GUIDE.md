# Open Trading Platform - Setup Guide

## Current Status

✅ **Completed:**
- kubectl installed at `C:\Users\user\kubectl.exe`
- helm installed at `C:\Users\user\helm.exe`
- Scaleway CLI installed and configured
- Scaleway account initialized (Project: Opentrader)

❌ **Issue:**
- Scaleway quota limit reached for private networks (1/1)
- Cannot create Kubernetes cluster until quota is increased

## Options to Proceed

### Option 1: Create Cluster Manually in Scaleway Console (EASIEST - Recommended)

**This bypasses the quota issue!**

1. Go to: https://console.scaleway.com/kubernetes/clusters
2. Click "Create Cluster"
3. Configure:
   - Name: `otp-cluster`
   - Region: Paris (fr-par)
   - Node Type: DEV1-M (3 nodes)
   - Network: Try "Public only" or "No private network" option
4. Wait 5-10 minutes for cluster to be ready
5. Connect:
   ```powershell
   .\open-trading-platform-master\connect-to-cluster.ps1
   ```

See detailed guide: `MANUAL-CLUSTER-SETUP.md`

### Option 2: Request Scaleway Quota Increase

1. Go to Scaleway Console: https://console.scaleway.com/support/tickets
2. Create a support ticket requesting:
   - Increase private network quota from 1 to 2 (or more)
   - Mention you're setting up a Kubernetes cluster for development
3. Usually approved within 24 hours

Once approved, run:
```powershell
.\open-trading-platform-master\create-cluster.ps1
```

### Option 2: Use Google Kubernetes Engine (GKE)

You have a setup script ready for GKE:

```powershell
.\open-trading-platform-master\setup-gke.ps1
```

Requirements:
- Google Cloud account with billing enabled
- gcloud CLI installed

### Option 3: Use Azure Kubernetes Service (AKS)

You have a setup script ready for AKS:

```powershell
.\open-trading-platform-master\setup-azure.ps1
```

Requirements:
- Azure account with subscription
- Azure CLI installed

### Option 4: Local Kubernetes with Docker Desktop

**Easiest for development/testing:**

1. Install Docker Desktop: https://www.docker.com/products/docker-desktop/
2. Enable Kubernetes in Docker Desktop settings
3. Wait for Kubernetes to start
4. Install OTP:

```powershell
# Install Git Bash (if not installed)
# Download from: https://git-scm.com/download/win

# Then run:
cd open-trading-platform-master\install
bash install.sh -v 1.1.0
```

### Option 5: Use MicroK8s (Linux/WSL)

If you have WSL installed:

```bash
# In WSL terminal
snap install microk8s --classic --channel=1.27/stable
microk8s enable dns hostpath-storage
microk8s start

# Clone and install
cd open-trading-platform-master/install
./install.sh -v 1.1.0 -m
```

## Installation Steps (Once Cluster is Ready)

### Prerequisites
- Kubernetes cluster running and kubectl configured
- Helm 3 installed
- Git Bash or WSL for running the install script

### Install OTP

```powershell
# Option A: Use the automated script
.\open-trading-platform-master\complete-setup.ps1

# Option B: Manual installation
cd open-trading-platform-master\install
bash install.sh -v 1.1.0
```

The installation will:
1. Install Kafka (message broker)
2. Install PostgreSQL (database)
3. Install Envoy (API gateway)
4. Install OTP services (trading platform)

This takes 10-15 minutes.

### Access OTP

After installation:

```powershell
# Check status
.\open-trading-platform-master\check-status.ps1

# Get the Envoy service URL
kubectl get service envoy -n envoy
```

Access the web client at: `http://<EXTERNAL-IP>:<PORT>`

**Login credentials (no password required):**
- `trader1`, `trader2` - Desk1 traders
- `support1` - Desk1 view-only
- `traderA`, `traderB` - DeskA traders
- `supportA` - DeskA view-only

## Useful Commands

```powershell
# Check all pods
kubectl get pods -A

# Check all services
kubectl get services -A

# View pod logs
kubectl logs <pod-name> -n <namespace>

# List helm releases
helm list -A

# Check cluster info
kubectl cluster-info

# Check Scaleway clusters
scw k8s cluster list

# Delete a cluster (when done)
scw k8s cluster delete <cluster-name> region=fr-par
```

## Architecture Overview

The OTP platform consists of:

**Infrastructure:**
- Kafka - Message broker for order/execution distribution
- PostgreSQL - Static data and configuration storage
- Envoy - API gateway and gRPC-web proxy

**Services:**
- `authorization-service` - User authentication
- `client-config-service` - UI configuration
- `static-data-service` - Instruments, markets, listings
- `market-data-service` - Market data distribution
- `market-data-gateway-fixsim` - FIX market data gateway
- `quote-aggregator` - Quote aggregation
- `order-data-service` - Order persistence
- `order-monitor` - Order monitoring
- `order-router` - Order routing
- `smart-router` - Smart order routing
- `vwap-strategy` - VWAP execution strategy
- `fix-sim-execution-venue` - FIX execution venue
- `fix-market-simulator` - Market simulator

**Client:**
- React-based web application
- Real-time order management
- Market data visualization
- Trading desk management

## Cost Estimates

**Scaleway (DEV1-M nodes):**
- 3 nodes × ~€17/month = ~€50/month (~$55/month)
- Your $500 credit = ~9 months of usage

**GKE (e2-medium nodes):**
- 3 nodes × ~$25/month = ~$75/month
- Free tier: $300 credit for 90 days

**Azure AKS (Standard_B2s nodes):**
- 3 nodes × ~$30/month = ~$90/month
- Free tier: $200 credit for 30 days

**Docker Desktop:**
- Free for development
- Runs on your local machine

## Troubleshooting

### Pods not starting
```powershell
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### Service not accessible
```powershell
kubectl get services -A
kubectl describe service <service-name> -n <namespace>
```

### Cluster connection issues
```powershell
kubectl config get-contexts
kubectl config use-context <context-name>
```

### Scaleway quota issues
- Contact support: https://console.scaleway.com/support/tickets
- Check quotas: https://console.scaleway.com/organization/settings

## Next Steps

1. **Choose your deployment option** (Scaleway after quota increase, GKE, Azure, or local)
2. **Create/connect to Kubernetes cluster**
3. **Run the installation script**
4. **Access the OTP web client**
5. **Start trading!**

## Support

- OTP GitHub: https://github.com/ettec/open-trading-platform
- Scaleway Console: https://console.scaleway.com
- Scaleway Support: https://console.scaleway.com/support/tickets

## Scripts Created

- `complete-setup.ps1` - Automated setup and installation
- `create-cluster.ps1` - Create Scaleway cluster
- `check-status.ps1` - Check OTP status
- `setup-scaleway.ps1` - Original Scaleway setup (has encoding issues)
- `setup-gke.ps1` - GKE setup
- `setup-azure.ps1` - Azure setup
