terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
variable "i_am_user_prefix" {
  default = "my-iam-user"
}

provider "aws" {
  region = "us-east-1"
}

# Create a IAM user
resource "aws_iam_user" "my_iam_user" {
  count = 3
  name = "${var.i_am_user_prefix}-${count.index + 1}"
}