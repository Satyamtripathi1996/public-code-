variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "Public subnets for bastion (pick one index in module)."
  type        = list(string)
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to SSH into bastion (e.g., [\"165.1.207.240/32\"])."
  type        = list(string)
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key pair name to SSH into bastion."
  type        = string
}

variable "tags" {
  type = map(string)
}
