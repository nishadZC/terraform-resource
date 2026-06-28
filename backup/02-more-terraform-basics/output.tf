output "iam_user_names" {
  value = aws_iam_user.my_iam_user[*].name
}
