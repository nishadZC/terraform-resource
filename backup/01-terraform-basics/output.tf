output "my_s3_bucket_name" {
  value = aws_s3_bucket.my_s3_bucket.bucket
}
output "my_s3_bucket_versioning_status" {
  value = aws_s3_bucket_versioning.versioning.versioning_configuration[0].status
}

output "my_iam_user_name" {
  value = aws_iam_user.my_iam_user.name
}