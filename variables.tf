variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "allowed_ip" {
  description = "Public IP allowed to access EC2 (replace with your machine IP)"
  default     = "103.45.67.89/32" #  replace with your actual IP
}
