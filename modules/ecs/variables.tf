variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where ECS and ALB are deployed"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for ALB and ECS tasks"
  type        = list(string)
}

variable "backend_image_uri" {
  description = "Full backend image URI including tag"
  type        = string
}

variable "frontend_image_uri" {
  description = "Full frontend image URI including tag"
  type        = string
}
variable "account_id" {
  description = "AWS Account ID"
  type        = string
}