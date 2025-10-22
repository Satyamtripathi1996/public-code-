output "alb_dns_name" {
  description = "Public URL for the app"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL writer endpoint"
  value       = module.rds.db_endpoint
}
