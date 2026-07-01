terraform {
  backend "s3" {
    bucket = "${var.environment}-eventify-bucket-apsouth1"
    key    = "${var.environment}/eventify/terraform.tfstate"
    region = "ap-south-1"
  }
}