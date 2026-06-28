# # EKS Cluster
# resource "aws_eks_cluster" "main" {
#   name            = var.cluster_name
#   role_arn        = aws_iam_role.eks_cluster_role.arn
#   version         = var.kubernetes_version

#   vpc_config {
#     subnet_ids              = concat(var.public_subnets, var.private_subnets)
#     endpoint_private_access = true
#     endpoint_public_access  = true
#     security_group_ids      = [aws_security_group.eks_cluster.id]
#   }

#   depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]

#   tags = {
#     Name = var.cluster_name
#   }
# }

# # EKS Node Group (Auto Scaling Group)
# resource "aws_eks_node_group" "main" {
#   cluster_name    = aws_eks_cluster.main.name
#   node_group_name = "${var.cluster_name}-node-group"
#   node_role_arn   = aws_iam_role.eks_node_role.arn
#   subnet_ids      = var.private_subnets
#   version         = var.kubernetes_version

#   scaling_config {
#     desired_size = var.desired_size
#     max_size     = var.max_size
#     min_size     = var.min_size
#   }

#   instance_types = [var.instance_type]

#   tags = {
#     Name = "${var.cluster_name}-node-group"
#   }

#   depends_on = [aws_iam_role_policy_attachment.eks_node_policy]
# }

# # IAM Role for EKS Cluster
# resource "aws_iam_role" "eks_cluster_role" {
#   name = "${var.cluster_name}-cluster-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "eks.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks_cluster_role.name
# }

# # IAM Role for EKS Nodes
# resource "aws_iam_role" "eks_node_role" {
#   name = "${var.cluster_name}-node-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_node_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_node_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_node_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_container_registry" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_node_role.name
# }

# # Security Group for EKS Cluster
# resource "aws_security_group" "eks_cluster" {
#   name        = "${var.cluster_name}-sg"
#   description = "Security group for EKS cluster"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.cluster_name}-sg"
#   }
# }

# # OIDC Provider for IRSA (IAM Roles for Service Accounts)
# data "tls_certificate" "eks" {
#   url = aws_eks_cluster.main.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
# }

# # IAM Role for Horizontal Pod Autoscaler (Metrics Server)
# resource "aws_iam_role" "metrics_server" {
#   name = "${var.cluster_name}-metrics-server"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.eks.arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:metrics-server"
#         }
#       }
#     }]
#   })
# }
