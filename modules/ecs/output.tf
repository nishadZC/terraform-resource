# Outputs  ← use these as your fixed URLs
output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "Fixed ALB DNS — never changes even after redeployment"
}

output "frontend_url" {
  value       = "http://${aws_lb.main.dns_name}"
  description = "Frontend URL"
}

output "backend_api_url" {
  value       = "http://${aws_lb.main.dns_name}:3001"
  description = "Set this as VITE_API_BASE_URL in Jenkins credentials"
}
