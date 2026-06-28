output "http_sg_id" {
  value = aws_security_group.http_sg.id
}
output "instance_public_ips" {
  value = values(aws_instance.devops-instance)[*].public_ip
}

output "instance_public_dns" {
  value = values(aws_instance.devops-instance)[*].public_dns
}
output "elb_dns_name" {
  value = aws_elb.devops-elb.dns_name
}