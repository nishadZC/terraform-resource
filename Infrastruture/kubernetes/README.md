# Kubernetes Deployment for Eventify

This directory contains all Kubernetes manifests for deploying the Eventify application to AWS EKS with auto-scaling capabilities.

## Files Overview

### 1. **EKS Terraform Configuration** (eks/)
- `main.tf` - EKS cluster, node group, IAM roles, security groups
- `variables.tf` - Input variables
- `outputs.tf` - Output values for connecting to the cluster

### 2. **Kubernetes Manifests** (kubernetes/)

#### `backend-deployment.yaml`
- Backend service deployment
- Service definition (ClusterIP)
- ConfigMap for non-sensitive environment variables
- Secret for sensitive credentials
- Liveness and readiness probes
- Resource requests and limits

#### `frontend-deployment.yaml`
- Frontend service deployment
- Service definition (ClusterIP)
- Liveness and readiness probes
- Resource requests and limits

#### `hpa.yaml` (Auto-Scaling Configuration)
**Backend HPA:**
- Min: 2 replicas, Max: 10 replicas
- Scales on: CPU (70%), Memory (80%), Requests/sec (1000 rps)
- Scale up: Immediately (0s stabilization)
- Scale down: Gradual (300s stabilization)

**Frontend HPA:**
- Min: 2 replicas, Max: 8 replicas
- Scales on: CPU (75%), Memory (80%), Requests/sec (2000 rps)

#### `ingress.yaml`
- AWS ALB Ingress Controller configuration
- Routes traffic to frontend and backend services
- SSL/TLS termination ready

#### `metrics-server.yaml`
- Required for HPA (Horizontal Pod Autoscaler)
- Collects metrics from kubelet on each node

#### `pod-disruption-budget.yaml`
- Ensures minimum availability during node maintenance
- Prevents all pods from being terminated simultaneously

#### `network-policy.yaml`
- Restricts traffic between pods
- Frontend can only communicate with backend
- Backend can only communicate with frontend, MongoDB, and external APIs

## Deployment Steps

### 1. Deploy EKS Cluster
```bash
cd eks/
terraform init
terraform plan
terraform apply
```

### 2. Configure kubectl
```bash
aws eks update-kubeconfig --region ap-south-1 --name eventify-eks-cluster
kubectl get nodes
```

### 3. Update Image URIs
Replace placeholders in YAML files:
```bash
sed -i 's|BACKEND_IMAGE_URI|YOUR_BACKEND_IMAGE_URI|g' kubernetes/backend-deployment.yaml
sed -i 's|FRONTEND_IMAGE_URI|YOUR_FRONTEND_IMAGE_URI|g' kubernetes/frontend-deployment.yaml
```

### 4. Deploy Metrics Server
```bash
kubectl apply -f kubernetes/metrics-server.yaml
```

### 5. Deploy Application
```bash
kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl apply -f kubernetes/hpa.yaml
kubectl apply -f kubernetes/pod-disruption-budget.yaml
kubectl apply -f kubernetes/network-policy.yaml
```

### 6. Install AWS Load Balancer Controller (for Ingress)
```bash
# Add OIDC provider (done in Terraform)

# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eventify-eks-cluster

# Deploy Ingress
kubectl apply -f kubernetes/ingress.yaml
```

## Monitoring & Scaling

### Check HPA Status
```bash
kubectl get hpa -w
kubectl describe hpa backend-hpa
kubectl describe hpa frontend-hpa
```

### View Pod Metrics
```bash
kubectl top nodes
kubectl top pods
```

### Check Scaling Events
```bash
kubectl get events --sort-by='.lastTimestamp'
```

### View Logs
```bash
kubectl logs -f deployment/backend -c backend
kubectl logs -f deployment/frontend -c frontend
```

## Scaling Thresholds

### Backend
- **Min Replicas**: 2
- **Max Replicas**: 10
- **Scale-up Trigger**: CPU > 70%, Memory > 80%, or RPS > 1000
- **Scale-down Trigger**: Resources < thresholds for 5 minutes

### Frontend
- **Min Replicas**: 2
- **Max Replicas**: 8
- **Scale-up Trigger**: CPU > 75%, Memory > 80%, or RPS > 2000
- **Scale-down Trigger**: Resources < thresholds for 5 minutes

## Resource Limits

### Backend
- **Request**: 250m CPU, 256Mi Memory
- **Limit**: 500m CPU, 512Mi Memory

### Frontend
- **Request**: 200m CPU, 256Mi Memory
- **Limit**: 400m CPU, 512Mi Memory

## Health Checks

### Backend
- **Liveness**: /health endpoint, 30s interval, fails after 3 retries
- **Readiness**: /health endpoint, 5s interval, fails after 2 retries

### Frontend
- **Liveness**: / endpoint, 30s interval, fails after 3 retries
- **Readiness**: / endpoint, 5s interval, fails after 2 retries

## Troubleshooting

### HPA Not Scaling
```bash
# Check if metrics are available
kubectl get deployment metrics-server -n kube-system
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Check HPA status
kubectl describe hpa backend-hpa
kubectl get hpa backend-hpa -o yaml
```

### Pods Not Running
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Network Issues
```bash
kubectl exec -it <pod-name> -- /bin/sh
# Inside pod:
wget http://backend:3001/health
```

## Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f kubernetes/

# Delete EKS cluster
terraform destroy -chdir=eks/
```

## Cost Optimization

1. **Use Spot Instances**: Modify node group to use spot pricing
2. **Enable Cluster Autoscaler**: Automatically scale node groups based on pod resource requests
3. **Use Reserved Instances**: For base load (min 2 nodes)
4. **Monitor Unused Resources**: Use tools like Kubecost

## Next Steps

1. Set up persistent storage (EBS, EFS)
2. Implement logging (CloudWatch, ELK)
3. Add monitoring (Prometheus, Grafana)
4. Implement CI/CD pipeline (GitHub Actions, GitLab CI)
5. Enable service mesh (Istio for advanced traffic management)
