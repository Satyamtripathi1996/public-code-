# AWS Nginx + RDS Infrastructure (Eval Project)

## Overview
This Terraform setup creates:
- A multi-AZ VPC
- An Auto Scaling Nginx web service with ALB
- A Multi-AZ RDS MySQL database

## Region
us-east-1 (N. Virginia)

## Deployment Steps
1. terraform init
2. terraform validate
3. terraform plan
4. terraform apply -auto-approve

## Scaling
- Scale up at CPU >= 65%
- Scale down at CPU <= 40%
