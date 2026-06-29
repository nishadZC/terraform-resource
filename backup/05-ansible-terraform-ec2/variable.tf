variable "aws_key_pair" {
  description = "Path to private key file"
  type        = string
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
variable "key_name" {
  description = "Name of the key pair"
  type        = string
  default     = "devops-keys"
}