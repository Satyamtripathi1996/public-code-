variable "project"            { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "instance_type"      { type = string }
variable "target_group_arn"   { type = string }
variable "alb_security_group_id" { type = string }
variable "tags"               { type = map(string) }

# NEW — to allow SSH only from bastion
variable "bastion_sg_id" {
  description = "Security group ID of bastion allowed to SSH into web EC2"
  type        = string
  default     = null
}
