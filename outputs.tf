output "vpc_id" {
  value = module.vpc.vpc_id
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "web_alb_dns" {
  value = module.ec2.alb_dns_name
}
