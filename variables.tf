variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name prefix for all resources"
  default     = "north-eval-eda"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.0.0/16"
  description = "VPC CIDR"
}

variable "azs" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  description = "CIDR(s) allowed to reach ALB (e.g. your IP / corporate IPs)"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM cert ARN for HTTPS (e.g. sbox.nabancard.io)"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "db_name"        { type = string  default = "appdb" }
variable "db_username"    { type = string  default = "dbadmin" }
variable "db_password"    { type = string  sensitive = true }  # put in tfvars
variable "kms_key_id"     { type = string  default = null }    # optional custom KMS
variable "tags" {
  type = map(string)
  default = {
    Owner   = "Eda.Top"
    Project = "Eval-Nginx-RDS"
  }
}
