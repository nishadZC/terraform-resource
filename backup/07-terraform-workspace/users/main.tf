terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  backend "s3" {
    bucket = "dev-backend-state-001"
    key    = "remote-state-users-dev"
    dynamodb_table = "terraform-locks"
    encrypt = true
    region = "ap-south-1"
  }
  
}
resource "aws_default_vpc" "default" {}

resource "aws_iam_user" "remote-user" {
  name = "${terraform.workspace}-remote-access-user"
}