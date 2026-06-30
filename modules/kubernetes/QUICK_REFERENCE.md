# Quick Reference: Kubernetes Deployment Checklist

## 📋 Pre-Deployment

- [ ] AWS CLI configured with correct credentials
- [ ] Terraform installed (v1.0+)
- [ ] kubectl installed (v1.28+)
- [ ] Helm installed (v3+)
- [ ] Container images pushed to ECR
- [ ] MongoDB connection string ready
- [ ] Secrets (JWT, API keys) prepared

## 🚀 Step-by-Step Deployment

### 1. Update Root Terraform (main.tf)
Add EKS module to your root `main.tf`:

```hcl
module "eks" {
  source = "./eks"

  cluster_name           = "eventify-eks-cluster"
  vpc_id                 = module.networking.dev_proj_1_vpc_id
  public_subnets         = module.networking.dev_proj_1_public_subnets
  private_subnets        = [module.networking.dev_proj_1_private_subnets]
  kubernetes_version     = "1.28"
  instance_type          = "t3.medium"
  desired_size           = 2
  min_size               = 1
  max_size               = 10
  backend_image_uri      = "${module.ecr.backend_repository_url}:latest"
  frontend_image_uri     = "${module.ecr.frontend_repository_url}:latest"
  account_id             = "YOUR_ACCOUNT_ID"
}
```

### 2. Deploy Infrastructure
```bash
# From root directory
cd eks/
terraform init
terraform apply
```
⏱️ **Time**: 15-20 minutes

### 3. Configure kubectl
```bash
CLUSTER_NAME=$(cd eks && terraform output -raw cluster_name)
aws eks update-kubeconfig --region ap-south-1 --name $CLUSTER_NAME
kubectl get nodes
```

### 4. Deploy Metrics Server
```bash
kubectl apply -f kubernetes/metrics-server.yaml
kubectl wait --for=condition=ready pod -l component=metrics-server -n kube-system --timeout=300s
```

### 5. Update Secrets and Images
Edit `kubernetes/backend-deployment.yaml`:
- Replace `BACKEND_IMAGE_URI` with your ECR image
- Replace secrets (MONGODB_URI, JWT_SECRET, etc.)

Edit `kubernetes/frontend-deployment.yaml`:
- Replace `FRONTEND_IMAGE_URI` with your ECR image

### 6. Deploy Application
```bash
kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl apply -f kubernetes/hpa.yaml
kubectl apply -f kubernetes/pod-disruption-budget.yaml
kubectl apply -f kubernetes/network-policy.yaml

# Verify deployments
kubectl get deployments
kubectl get pods
```

### 7. Deploy Ingress (Optional but Recommended)
```bash
# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eventify-eks-cluster

# Deploy Ingress
kubectl apply -f kubernetes/ingress.yaml

# Get ALB DNS
kubectl get ingress
```

---

## 📊 Monitor Scaling

### Real-Time HPA Monitoring
```bash
# Watch HPA scaling
kubectl get hpa -w

# Output:
# NAME            REFERENCE            TARGETS                    MINPODS   MAXPODS   REPLICAS
# backend-hpa     Deployment/backend   2%/70%, 256Mi/80%         2         10        2
# frontend-hpa    Deployment/frontend  5%/75%, 300Mi/80%         2         8         2
```

### Generate Load (for testing)
```bash
# Backend load
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  sh -c "while sleep 0.01; do wget -q -O- http://backend:3001/api; done"

# Monitor scaling
kubectl get hpa -w
kubectl top pods -w
```

### View Scaling Events
```bash
# All events (sorted by time)
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Filter for HPA
kubectl get events | grep -i hpa

# Watch in real-time
kubectl get events -w
```

---

## 🔍 Troubleshooting

### Pods Not Running
```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Check deployment
kubectl describe deployment backend
```

### HPA Not Scaling
```bash
# 1. Check metrics are available
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# 2. Check HPA status
kubectl describe hpa backend-hpa
kubectl get hpa backend-hpa -o yaml

# 3. Check metrics-server
kubectl get deployment -n kube-system metrics-server
kubectl logs -n kube-system -l component=metrics-server
```

### No External IP/DNS
```bash
# Check service
kubectl get svc

# For ALB Ingress
kubectl get ingress
kubectl describe ingress eventify-ingress

# Wait for ALB provisioning (2-3 minutes)
kubectl get ingress eventify-ingress -o wide
```

### Pod Eviction
```bash
# Check node resources
kubectl top nodes
kubectl describe node <node-name>

# Check for memory/disk pressure
kubectl get nodes -o wide
```

---

## 📈 Common Operations

### Scale Deployment Manually
```bash
kubectl scale deployment backend --replicas=5
kubectl scale deployment frontend --replicas=3
```

### Update Application Image
```bash
kubectl set image deployment/backend \
  backend=YOUR_REGISTRY/backend:v2 \
  --record

kubectl rollout status deployment/backend
```

### Restart Deployment
```bash
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/frontend
```

### View Logs
```bash
# Current logs
kubectl logs deployment/backend

# Follow logs
kubectl logs -f deployment/backend

# Last 100 lines
kubectl logs deployment/backend --tail=100

# Previous pod (if crashed)
kubectl logs deployment/backend --previous
```

### Execute Command in Pod
```bash
# Get shell access
kubectl exec -it <pod-name> -- /bin/sh

# Run single command
kubectl exec <pod-name> -- curl http://localhost:3001/health
```

---

## 🛠️ Useful kubectl Commands

```bash
# Get resources
kubectl get pods               # All pods
kubectl get nodes              # All nodes
kubectl get svc                # All services
kubectl get hpa                # All HPAs
kubectl get events             # All events

# Describe resources
kubectl describe pod <name>    # Detailed pod info
kubectl describe node <name>   # Node resources and conditions
kubectl describe hpa <name>    # HPA scaling details

# Logs
kubectl logs <pod-name>        # Pod logs
kubectl logs -f <pod-name>     # Follow logs
kubectl logs --previous <pod>  # Previous container logs

# Execute
kubectl exec -it <pod> -- sh   # Interactive shell
kubectl exec <pod> -- <cmd>    # Run command

# Scaling
kubectl scale deployment <name> --replicas=N

# Restart
kubectl rollout restart deployment/<name>
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>

# Debugging
kubectl port-forward svc/<name> 8080:80
kubectl top nodes
kubectl top pods
```

---

## 📊 Scaling Parameters Reference

### Backend
- **Min Replicas**: 2
- **Max Replicas**: 10
- **CPU Target**: 70%
- **Memory Target**: 80%
- **RPS Threshold**: 1000/pod
- **Scale-up delay**: Immediate
- **Scale-down delay**: 5 minutes

### Frontend
- **Min Replicas**: 2
- **Max Replicas**: 8
- **CPU Target**: 75%
- **Memory Target**: 80%
- **RPS Threshold**: 2000/pod
- **Scale-up delay**: Immediate
- **Scale-down delay**: 5 minutes

---

## 💡 Tips & Best Practices

1. **Always set resource requests/limits**
   - Helps scheduler make better decisions
   - Prevents pod eviction

2. **Use readiness probes**
   - Don't send traffic to unready pods
   - Faster recovery from failures

3. **Monitor metrics regularly**
   - CPU usage should stay < 70%
   - Memory should stay < 80%
   - RPS should be distributed evenly

4. **Test scaling before production**
   - Generate load with load testing tools
   - Verify HPA responds correctly
   - Check application behavior under load

5. **Update gradually**
   - Use RollingUpdate strategy
   - Test in staging first
   - Monitor after deployment

---

## 🚨 Emergency Procedures

### Scale Down Immediately
```bash
# Reduce max replicas
kubectl patch hpa backend-hpa -p '{"spec":{"maxReplicas":2}}'
kubectl patch hpa frontend-hpa -p '{"spec":{"maxReplicas":2}}'
```

### Delete Stuck Pod
```bash
kubectl delete pod <pod-name> --grace-period=0 --force
```

### Emergency Stop
```bash
kubectl scale deployment backend --replicas=1
kubectl scale deployment frontend --replicas=1
```

### Rollback Deployment
```bash
kubectl rollout history deployment/backend
kubectl rollout undo deployment/backend --to-revision=2
```

---

## 📞 Support Resources

- Kubernetes Docs: https://kubernetes.io/docs/
- AWS EKS: https://docs.aws.amazon.com/eks/
- HPA Guide: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

