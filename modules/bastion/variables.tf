variable "project"           { type = string }
variable "vpc_id"            { type = string }
variable "public_subnet_id"  { type = string }       # one public subnet id
variable "allowed_cidrs_ssh" { type = list(string) } # e.g. ["165.1.207.240/32"]
variable "instance_type"     { type = string, default = "t3.micro" }
variable "key_name"          { type = string }       # existing key pair name
variable "tags"              { type = map(string) }
