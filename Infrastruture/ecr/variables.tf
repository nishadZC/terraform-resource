variable "frontend_repository_name" {
  description = "Name of the ECR repository for the frontend application"
  type        = string
  default     = "frontend-repo"
}

variable "backend_repository_name" {
  description = "Name of the ECR repository for the backend application"
  type        = string
  default     = "backend-repo"
}