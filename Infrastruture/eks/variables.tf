# variable "cluster_name" {
#   description = "EKS cluster name"
#   type        = string
#   default     = "eventify-eks-cluster"
# }

# variable "kubernetes_version" {
#   description = "Kubernetes version"
#   type        = string
#   default     = "1.28"
# }

# variable "vpc_id" {
#   description = "VPC ID"
#   type        = string
# }

# variable "public_subnets" {
#   description = "Public subnet IDs"
#   type        = list(string)
# }

# variable "private_subnets" {
#   description = "Private subnet IDs"
#   type        = list(string)
# }

# variable "desired_size" {
#   description = "Desired number of worker nodes"
#   type        = number
#   default     = 2
# }

# variable "min_size" {
#   description = "Minimum number of worker nodes"
#   type        = number
#   default     = 1
# }

# variable "max_size" {
#   description = "Maximum number of worker nodes"
#   type        = number
#   default     = 10
# }

# variable "instance_type" {
#   description = "EC2 instance type for nodes"
#   type        = string
#   default     = "t3.medium"
# }

# variable "backend_image_uri" {
#   description = "Backend Docker image URI"
#   type        = string
# }

# variable "frontend_image_uri" {
#   description = "Frontend Docker image URI"
#   type        = string
# }

# variable "account_id" {
#   description = "AWS Account ID"
#   type        = string
# }
