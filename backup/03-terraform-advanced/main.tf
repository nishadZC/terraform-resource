terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "iam_users" {
  default = {
    vinayaka = { country = "India" }
    rahula   = { country = "USA" }
    praveena = { country = "Canada" }
    rama     = { country = "UK" }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create a IAM user
resource "aws_iam_user" "my_iam_user" {
  for_each = var.iam_users
  name = each.key
  tags = {
    country = each.value.country
  }
}