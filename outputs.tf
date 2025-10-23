output "alb_dns_name"       { value = module.alb.alb_dns_name }
output "rds_endpoint"       { value = module.rds.db_endpoint }
output "bastion_public_ip"  { value = module.bastion.bastion_public_ip }
