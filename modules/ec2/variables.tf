variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "north-eval-eda"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# Who can hit the public ALB (your /32 or corporate ranges)
variable "allowed_ingress_cidrs" {
  type = list(string)
}

# ACM certificate (Issued in us-east-1) for HTTPS
variable "acm_certificate_arn" {
  type = string
}

# EC2
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# PostgreSQL settings
variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

# SSH key pair name (for bastion)
variable "key_name" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    Owner   = "Eda.Top"
    Project = "Eval-Nginx-RDS"
  }
}
