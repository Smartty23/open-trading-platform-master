# Manual Cluster Creation Guide

## Create Scaleway Kubernetes Cluster via Console

### Step 1: Create the Cluster

1. Go to: https://console.scaleway.com/kubernetes/clusters
2. Click **"Create Cluster"**
3. Configure:
   - **Name:** `otp-cluster`
   - **Region:** Paris (fr-par) or any region
   - **Kubernetes Version:** Latest stable (1.28 or newer)
   - **CNI Plugin:** Cilium (default)
   - **Private Network:** 
     - **Option A:** Create new (if quota allows)
     - **Option B:** Select "Public network only" or "No private network" if available
     - **Option C:** Use existing network if you have one

### Step 2: Configure Node Pool

1. **Pool Name:** `otp-pool`
2. **Node Type:** DEV1-M (3 vCPU, 4GB RAM) - good for learning
   - Or GP1-XS (4 vCPU, 16GB RAM) - better performance
3. **Number of Nodes:** 3
4. **Autoscaling:** Disabled (for cost control)
5. **Auto-upgrade:** Optional (your choice)

### Step 3: Review and Create

- **Estimated Cost:** ~€50-60/month (~$55-65/month)
- Your $500 credit covers ~8-9 months
- Click **"Create Cluster"**
- Wait 5-10 minutes for cluster to be ready

### Step 4: Connect to Your Cluster

Once the cluster shows "Ready" status:

```powershell
# Get your cluster ID from the console or run:
scw k8s cluster list

# Install kubeconfig (replace CLUSTER_ID with your actual ID)
scw k8s kubeconfig install <CLUSTER_ID> region=fr-par

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Step 5: Install OTP

```powershell
# Option A: Automated (if you have Git Bash)
cd open-trading-platform-master\install
bash install.sh -v 1.1.0

# Option B: Use the complete setup script
.\open-trading-platform-master\complete-setup.ps1
```

## Alternative: Use Public/Open Network Configuration

If you want to avoid private network entirely for learning:

### Scaleway Kapsule Public Configuration

Scaleway Kapsule clusters can work without private networks, but this is less common. The console will guide you through available options based on your quota.

**Security Note for Learning:**
- For a learning project, public networking is fine
- The OTP services will still be behind the Envoy gateway
- You can add network policies later if needed

### After Manual Creation

Once your cluster is created and you've connected via kubeconfig, simply run:

```powershell
# Check connection
kubectl get nodes

# Should show 3 nodes in Ready state
# Then install OTP
cd open-trading-platform-master\install
bash install.sh -v 1.1.0
```

## Quick Connect Script

After creating the cluster manually, use this to connect:

```powershell
# List your clusters
scw k8s cluster list

# Copy the cluster ID, then:
$clusterId = "YOUR_CLUSTER_ID_HERE"
$region = "fr-par"

# Install kubeconfig
scw k8s kubeconfig install $clusterId region=$region

# Verify
kubectl get nodes
kubectl cluster-info

# Check status
.\open-trading-platform-master\check-status.ps1
```

## What to Expect

**Cluster Creation Time:** 5-10 minutes
**OTP Installation Time:** 10-15 minutes
**Total Setup Time:** ~20-25 minutes

**After Installation:**
1. Get Envoy service IP: `kubectl get service envoy -n envoy`
2. Access OTP at: `http://<EXTERNAL-IP>:<PORT>`
3. Login as: `trader1`, `trader2`, `support1`, etc. (no password)

## Troubleshooting

### Can't create cluster - quota issue
- Try selecting "No private network" or "Public only" option
- Or request quota increase via support ticket

### Cluster stuck in "Creating" state
- Wait up to 15 minutes
- Check Scaleway status page: https://status.scaleway.com
- Contact support if it takes longer

### Can't connect after creation
```powershell
# Make sure you have the right context
kubectl config get-contexts

# Switch if needed
kubectl config use-context <context-name>
```

## Cost Management

**Monitor your usage:**
- Billing: https://console.scaleway.com/billing/consumption
- Set up billing alerts in console
- Delete cluster when not in use: `scw k8s cluster delete <cluster-id> region=fr-par`

**To save costs during learning:**
- Delete cluster when not actively using it
- Recreate when needed (takes 5-10 minutes)
- Your data will be lost, but it's easy to reinstall OTP
