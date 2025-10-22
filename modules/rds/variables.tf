variable "project"            { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "db_name"            { type = string }
variable "db_username"        { type = string }
variable "db_password"        { type = string, sensitive = true }
variable "kms_key_id"         { type = string, default = null }
variable "web_sg_id"          { type = string } # only web tier can reach DB
variable "tags"               { type = map(string) }
