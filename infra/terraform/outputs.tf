output "app_url" {
  value       = "${local.app_url_scheme}://${local.app_fqdn}"
  description = "Application URL (Cloudflare DNS/SSL setup is required)"
}

output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "ALB DNS name"
}

output "cloudflare_cname_target" {
  value       = aws_lb.app.dns_name
  description = "Create CNAME for app subdomain in Cloudflare DNS to this ALB DNS name"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR repository URL"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS cluster name"
}

output "web_service_name" {
  value       = aws_ecs_service.web.name
  description = "ECS web service name"
}

output "worker_service_name" {
  value       = aws_ecs_service.worker.name
  description = "ECS worker service name"
}

output "rds_endpoint" {
  value       = aws_db_instance.main.address
  description = "RDS endpoint"
}

output "redis_endpoint" {
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
  description = "Redis primary endpoint"
}
