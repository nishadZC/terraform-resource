# output "cluster_id" {
#   description = "EKS cluster ID"
#   value       = aws_eks_cluster.main.id
# }

# output "cluster_endpoint" {
#   description = "EKS cluster endpoint"
#   value       = aws_eks_cluster.main.endpoint
# }

# output "cluster_name" {
#   description = "EKS cluster name"
#   value       = aws_eks_cluster.main.name
# }

# output "cluster_ca_certificate" {
#   description = "Base64 encoded cluster CA certificate"
#   value       = aws_eks_cluster.main.certificate_authority[0].data
#   sensitive   = true
# }

# output "node_group_id" {
#   description = "EKS node group ID"
#   value       = aws_eks_node_group.main.id
# }

# output "oidc_provider_arn" {
#   description = "ARN of OIDC provider"
#   value       = aws_iam_openid_connect_provider.eks.arn
# }
