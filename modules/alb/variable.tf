variable "project"               { type = string }
variable "vpc_id"                { type = string }
variable "public_subnet_ids"     { type = list(string) }
variable "allowed_ingress_cidrs" { type = list(string) }
variable "acm_certificate_arn"   { type = string }
variable "tags"                  { type = map(string) }
