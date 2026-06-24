output "alb_dns_name" {
  description = "DNS public URL of the Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_frontend_url" {
  description = "ECR Repository URL for Frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_ventas_url" {
  description = "ECR Repository URL for Ventas"
  value       = aws_ecr_repository.ventas.repository_url
}

output "ecr_despachos_url" {
  description = "ECR Repository URL for Despachos"
  value       = aws_ecr_repository.despachos.repository_url
}
