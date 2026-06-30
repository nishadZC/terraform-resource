# #!/bin/bash

# # Kubernetes Deployment Helper Script for Eventify
# # This script automates the deployment of EKS cluster and Kubernetes manifests

# set -e

# # Colors for output
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# NC='\033[0m' # No Color

# echo -e "${YELLOW}=== Eventify Kubernetes Deployment Guide ===${NC}\n"

# # Step 1: Deploy EKS Cluster
# echo -e "${YELLOW}Step 1: Deploying EKS Cluster...${NC}"
# read -p "Do you want to deploy the EKS cluster? (yes/no) " -n 3 -r
# echo
# if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
#     cd eks/
#     terraform init
#     terraform plan -out=tfplan
#     echo -e "${YELLOW}Review the plan above. Type 'yes' to apply:${NC}"
#     terraform apply tfplan
#     cd ..
#     echo -e "${GREEN}✓ EKS cluster deployed successfully${NC}\n"
# else
#     echo -e "${RED}✗ Skipped EKS deployment${NC}\n"
# fi

# # Step 2: Configure kubectl
# echo -e "${YELLOW}Step 2: Configuring kubectl...${NC}"
# CLUSTER_NAME=$(cd eks && terraform output -raw cluster_name)
# REGION="ap-south-1"
# aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
# echo -e "${GREEN}✓ kubectl configured successfully${NC}"
# echo "Verifying cluster connection..."
# kubectl get nodes
# echo

# # Step 3: Wait for nodes to be ready
# echo -e "${YELLOW}Step 3: Waiting for worker nodes to be ready...${NC}"
# kubectl wait --for=condition=ready nodes --all --timeout=600s
# echo -e "${GREEN}✓ All nodes are ready${NC}\n"

# # Step 4: Update image URIs in manifests
# echo -e "${YELLOW}Step 4: Updating container image URIs...${NC}"
# read -p "Enter backend image URI (ECR): " BACKEND_IMAGE
# read -p "Enter frontend image URI (ECR): " FRONTEND_IMAGE

# sed -i "s|BACKEND_IMAGE_URI|$BACKEND_IMAGE|g" kubernetes/backend-deployment.yaml
# sed -i "s|FRONTEND_IMAGE_URI|$FRONTEND_IMAGE|g" kubernetes/frontend-deployment.yaml
# echo -e "${GREEN}✓ Image URIs updated${NC}\n"

# # Step 5: Update secrets
# echo -e "${YELLOW}Step 5: Updating secrets in manifests...${NC}"
# read -p "Enter MongoDB URI: " MONGODB_URI
# read -p "Enter JWT secret: " JWT_SECRET
# read -p "Enter Cloudinary URL: " CLOUDINARY_URL
# read -p "Enter Cloudinary API Secret: " CLOUDINARY_API_SECRET

# sed -i "s|mongodb+srv://user:pass@cluster.mongodb.net/database|$MONGODB_URI|g" kubernetes/backend-deployment.yaml
# sed -i "s|your-jwt-secret-key|$JWT_SECRET|g" kubernetes/backend-deployment.yaml
# sed -i "s|cloudinary://key:secret@cloud|$CLOUDINARY_URL|g" kubernetes/backend-deployment.yaml
# sed -i "s|your-cloudinary-api-secret|$CLOUDINARY_API_SECRET|g" kubernetes/backend-deployment.yaml
# echo -e "${GREEN}✓ Secrets updated${NC}\n"

# # Step 6: Deploy Metrics Server
# echo -e "${YELLOW}Step 6: Deploying Metrics Server (required for auto-scaling)...${NC}"
# kubectl apply -f kubernetes/metrics-server.yaml
# echo "Waiting for metrics-server to be ready..."
# kubectl wait --for=condition=ready pod -l component=metrics-server -n kube-system --timeout=300s
# echo -e "${GREEN}✓ Metrics Server deployed${NC}\n"

# # Step 7: Deploy Application
# echo -e "${YELLOW}Step 7: Deploying Eventify application...${NC}"
# kubectl apply -f kubernetes/backend-deployment.yaml
# kubectl apply -f kubernetes/frontend-deployment.yaml
# echo "Waiting for deployments to be ready..."
# kubectl wait --for=condition=available --timeout=600s deployment/backend deployment/frontend
# echo -e "${GREEN}✓ Application deployed${NC}\n"

# # Step 8: Deploy Auto-scaling
# echo -e "${YELLOW}Step 8: Deploying Horizontal Pod Autoscalers...${NC}"
# kubectl apply -f kubernetes/hpa.yaml
# echo -e "${GREEN}✓ HPA configured${NC}\n"

# # Step 9: Deploy Pod Disruption Budgets
# echo -e "${YELLOW}Step 9: Deploying Pod Disruption Budgets...${NC}"
# kubectl apply -f kubernetes/pod-disruption-budget.yaml
# echo -e "${GREEN}✓ PDB configured${NC}\n"

# # Step 10: Deploy Network Policies
# echo -e "${YELLOW}Step 10: Deploying Network Policies...${NC}"
# kubectl apply -f kubernetes/network-policy.yaml
# echo -e "${GREEN}✓ Network policies configured${NC}\n"

# # Step 11: Install AWS Load Balancer Controller
# echo -e "${YELLOW}Step 11: Installing AWS Load Balancer Controller...${NC}"
# read -p "Do you want to install AWS Load Balancer Controller for Ingress? (yes/no) " -n 3 -r
# echo
# if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
#     helm repo add eks https://aws.github.io/eks-charts
#     helm repo update
#     helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
#       -n kube-system \
#       --set clusterName=$CLUSTER_NAME \
#       --set vpcId=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=dev-proj-jenkins-ap-south-vpc-1" --query 'Vpcs[0].VpcId' --output text)
#     echo -e "${GREEN}✓ AWS Load Balancer Controller installed${NC}\n"
# else
#     echo -e "${YELLOW}⊘ Skipped AWS Load Balancer Controller installation${NC}\n"
# fi

# # Step 12: Deploy Ingress
# echo -e "${YELLOW}Step 12: Deploying Ingress...${NC}"
# read -p "Do you want to deploy Ingress? (yes/no) " -n 3 -r
# echo
# if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
#     read -p "Enter your domain (e.g., example.com): " DOMAIN
#     sed -i "s|yourdomain.com|$DOMAIN|g" kubernetes/ingress.yaml
#     kubectl apply -f kubernetes/ingress.yaml
#     echo -e "${GREEN}✓ Ingress deployed${NC}"
#     echo "Waiting for ALB to be provisioned (this may take a few minutes)..."
#     sleep 30
#     ALB_DNS=$(kubectl get ingress eventify-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
#     echo -e "${GREEN}Your ALB DNS: $ALB_DNS${NC}\n"
# else
#     echo -e "${YELLOW}⊘ Skipped Ingress deployment${NC}\n"
# fi

# # Summary
# echo -e "${GREEN}=== Deployment Complete ===${NC}\n"
# echo "Useful commands:"
# echo "  Check HPA status:       kubectl get hpa -w"
# echo "  View pod metrics:       kubectl top pods"
# echo "  View deployment logs:   kubectl logs -f deployment/backend"
# echo "  Watch scaling events:   kubectl get events --sort-by='.lastTimestamp'"
# echo "  Get service info:       kubectl get svc"
# echo
# echo "Next steps:"
# echo "  1. Update your DNS records to point to the ALB"
# echo "  2. Monitor scaling: kubectl get hpa -w"
# echo "  3. Check logs: kubectl logs -f deployment/backend"
