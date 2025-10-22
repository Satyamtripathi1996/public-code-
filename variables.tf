variable "region"        { type = string, default = "us-east-1" }
variable "project_name"  { type = string, default = "north-eval-eda" }
variable "vpc_cidr"      { type = string, default = "10.20.0.0/16" }
variable "azs"           { type = list(string), default = ["us-east-1a","us-east-1b"] }

# who can hit the ALB (use your /32 or corp CIDR ranges)
variable "allowed_ingress_cidrs" { type = list(string) }

# ACM for HTTPS (Issued in us-east-1)
variable "acm_certificate_arn"   { type = string }

variable "instance_type" { type = string, default = "t3.micro" }

# DB settings (PostgreSQL)
variable "db_name"     { type = string, default = "appdb" }
variable "db_username" { type = string, default = "dbadmin" }
variable "db_password" { type = string, sensitive = true }

variable "tags" {
  type = map(string)
  default = { Owner = "Eda.Top", Project = "Eval-Nginx-RDS" }
}
