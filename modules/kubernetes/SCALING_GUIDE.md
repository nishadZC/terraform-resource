# Complete Kubernetes Scaling Architecture for Eventify

## Overview
This setup provides:
- **AWS EKS** (Managed Kubernetes cluster)
- **Horizontal Pod Autoscaling (HPA)** based on CPU, Memory, and Requests/sec
- **AWS Application Load Balancer** for ingress traffic
- **Network policies** for security
- **Resource limits** for efficient scheduling
- **Health checks** for reliability

---

## 🏗️ Architecture Diagram

```
                    ┌─────────────────────────────┐
                    │   Internet (0.0.0.0/0)      │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  AWS Application Load       │
                    │  Balancer (ALB)             │
                    │  - Port 80  → Frontend      │
                    │  - Port 3001 → Backend      │
                    └──────────────┬──────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│  EKS Cluster      │     │  EKS Cluster      │     │  EKS Cluster      │
│  (ap-south-1a)    │     │  (ap-south-1b)    │     │  (ap-south-1c)    │
│                   │     │                   │     │                   │
│ ┌─────────────┐   │     │ ┌─────────────┐   │     │ ┌─────────────┐   │
│ │ Backend Pod │   │     │ │ Frontend Pod│   │     │ │ Backend Pod │   │
│ │ (3001)      │   │     │ │ (80)        │   │     │ │ (3001)      │   │
│ └─────────────┘   │     │ └─────────────┘   │     │ └─────────────┘   │
│                   │     │                   │     │                   │
│ ┌─────────────┐   │     │ ┌─────────────┐   │     │ ┌─────────────┐   │
│ │ Frontend Pod│   │     │ │ Backend Pod │   │     │ │ Frontend Pod│   │
│ │ (80)        │   │     │ │ (3001)      │   │     │ │ (80)        │   │
│ └─────────────┘   │     │ └─────────────┘   │     │ └─────────────┘   │
└───────────────────┘     └───────────────────┘     └───────────────────┘
        │                          │                          │
        └──────────────────────────┼──────────────────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  HPA (Auto-Scaling)         │
                    │  Monitors: CPU, Memory, RPS │
                    └──────────────────────────────┘
```

---

## 📊 Scaling Behavior

### Backend Service
```
Load (RPS)
    10
     9 ▲
     8 │                              Scale to 10 pods
     7 │                         ╱─────┐
     6 │                    ╱───┘      │
     5 │               ╱──┘            │
     4 │          ╱───┘                │
     3 │      ╱──┘                     │
     2 │ ────┘                         │
     1 │                               ▼ Scale down to 2 pods
     0 └─────────────────────────────────────────────
       0  1  2  3  4  5  6  7  8  9  10  11  12 Hours

Metrics Triggers:
├─ CPU > 70%        → Scale UP
├─ CPU < 20%        → Scale DOWN (after 5 min)
├─ Memory > 80%     → Scale UP
├─ Memory < 30%     → Scale DOWN (after 5 min)
└─ RPS > 1000/pod   → Scale UP
```

### Frontend Service
- Max: 8 replicas (Frontend is stateless and lighter)
- Min: 2 replicas
- RPS threshold: 2000 per pod (higher than backend)

---

## 🚀 Deployment Process

### Phase 1: Infrastructure
```bash
# 1. Deploy EKS cluster, node groups, security groups
cd eks/
terraform init
terraform apply
```

**Creates:**
- EKS cluster in ap-south-1
- 2-10 worker nodes (t3.medium)
- OIDC provider for IRSA
- IAM roles for cluster and nodes

### Phase 2: Kubernetes Setup
```bash
# 2. Deploy metrics server (required for HPA)
kubectl apply -f kubernetes/metrics-server.yaml

# 3. Deploy applications
kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/frontend-deployment.yaml

# 4. Configure auto-scaling
kubectl apply -f kubernetes/hpa.yaml
```

### Phase 3: Networking
```bash
# 5. Install ALB controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller

# 6. Deploy ingress
kubectl apply -f kubernetes/ingress.yaml
```

---

## 🔄 How Auto-Scaling Works

### 1. Metrics Collection
```
kubelet (on each node)
    ↓ (every 15s)
metrics-server (aggregates)
    ↓
Kubernetes API
    ↓
HPA Controller (checks every 15s)
```

### 2. Scaling Decision
```
HPA Controller:
1. Check current metrics (CPU, Memory, RPS)
2. Compare with thresholds
3. Calculate desired replica count
4. Apply stabilization window
5. Update deployment
```

### 3. Pod Creation
```
Scale-Up Event:
├─ HPA decides: need 3 pods
├─ Scheduler finds node with resources
├─ Kubelet pulls image
├─ Pod starts containers
├─ Readiness probe checks health
├─ ALB adds to target group
└─ Receives traffic

Scale-Down Event (with PDB):
├─ HPA decides: reduce to 2 pods
├─ Select pod to terminate
├─ Check PodDisruptionBudget (min 1 available)
├─ Remove from ALB
├─ Send SIGTERM to container
├─ Wait 30s for graceful shutdown
└─ Force kill if needed
```

---

## 📈 Monitoring Scaling

### View HPA Status
```bash
# Watch real-time
kubectl get hpa -w

# Detailed info
kubectl describe hpa backend-hpa
kubectl describe hpa frontend-hpa

# JSON output
kubectl get hpa backend-hpa -o json | jq '.status'
```

### Check Metrics
```bash
# CPU and Memory per pod
kubectl top pods

# Per node
kubectl top nodes

# Specific pod
kubectl top pod <pod-name>
```

### Watch Scaling Events
```bash
kubectl get events --sort-by='.lastTimestamp'

# Filter for HPA events
kubectl get events | grep HPA
```

### View Pod Logs
```bash
# Last 50 lines
kubectl logs -f deployment/backend --tail=50

# Specific pod
kubectl logs <pod-name>

# All pods in deployment
kubectl logs -f deployment/backend --all-containers=true
```

---

## 🎯 Performance Tuning

### Adjust Scaling Thresholds
Edit `hpa.yaml`:
```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 70  # Change this value
```

### Adjust Stabilization
```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0    # Immediate scale up
  scaleDown:
    stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
```

### Resource Requests
Edit deployments:
```yaml
resources:
  requests:
    cpu: 250m      # Guaranteed minimum
    memory: 256Mi
  limits:
    cpu: 500m      # Hard maximum
    memory: 512Mi
```

---

## 🛡️ Security Features

### Network Policies
- Frontend can only send traffic to backend
- Backend can only communicate with frontend and external services
- DNS allowed for all pods

### Pod Disruption Budgets
- Ensures minimum 1 pod is always running during node maintenance
- Prevents complete service outage

### Resource Limits
- Prevents pods from consuming entire node resources
- Ensures fair distribution

---

## 📊 Cost Estimation

### Monthly Cost (ap-south-1)
```
2 t3.medium nodes (running 24/7):     $40
Auto-scaling to 10 nodes (peak):      $200 (temporary)
EKS control plane:                    $73
ALB:                                  $20
Data transfer:                        $15
─────────────────────────────────
Estimated Monthly:                    $348 (base) + variable
```

### Cost Optimization
1. **Use Spot Instances** (70% discount): Modify instance type in variables
2. **Autoscale Node Groups**: Use Cluster Autoscaler
3. **Reserved Instances**: For base 2-3 nodes

---

## ⚠️ Troubleshooting

### HPA Not Scaling
```bash
# Check metrics availability
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Check HPA controller logs
kubectl logs -n kube-system deployment/metrics-server

# Debug HPA
kubectl describe hpa backend-hpa
```

### Pods Stuck in Pending
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes
kubectl describe node <node-name>
```

### High Latency During Scaling
```bash
# Check pod startup time
kubectl get pods -o wide

# Verify readiness probes
kubectl describe deployment backend
```

---

## 🔄 Update Strategy

### Rolling Update (Current)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```
- Creates 1 new pod
- Waits for readiness
- Terminates old pod
- Zero downtime, slower deployment

### Blue-Green Update
- Deploy new version alongside old
- Switch traffic atomically
- Faster but uses more resources

---

## 📝 Maintenance Checklist

- [ ] Monitor cluster usage monthly
- [ ] Update Kubernetes version quarterly
- [ ] Review and update security policies
- [ ] Test disaster recovery
- [ ] Review and optimize resource requests
- [ ] Monitor costs and optimize spending

