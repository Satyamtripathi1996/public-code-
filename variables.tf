variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "allowed_ip" {
  description = "Allowed public IP for SSH/HTTP access"
  default     = "165.1.207.240" # this is my machine ip 
}
