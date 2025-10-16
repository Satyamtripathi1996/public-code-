variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}
