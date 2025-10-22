module "vpc" {
  source   = "./modules/vpc"
  project  = var.project_name
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
  tags     = var.tags
}

module "alb" {
  source                = "./modules/alb"
  project               = var.project_name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  allowed_ingress_cidrs = var.allowed_ingress_cidrs
  acm_certificate_arn   = var.acm_certificate_arn
  tags                  = var.tags
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
}

module "rds" {
  source               = "./modules/rds"
  project              = var.project_name
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  web_sg_id            = module.ec2.web_sg_id
  tags                 = var.tags
}
