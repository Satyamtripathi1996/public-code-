# ... your provider + existing modules (vpc, alb, rds) ...

module "bastion" {
  source            = "./modules/bastion"
  project           = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  allowed_cidrs_ssh = var.allowed_ingress_cidrs
  key_name          = var.key_name
  tags              = var.tags
}

module "ec2" {
  source                 = "./modules/ec2"
  project                = var.project_name
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  instance_type          = var.instance_type
  target_group_arn       = module.alb.target_group_arn
  alb_security_group_id  = module.alb.alb_sg_id
  tags                   = var.tags

  # NEW: allow SSH to web EC2 only from bastion
  bastion_sg_id          = module.bastion.bastion_sg_id
}
