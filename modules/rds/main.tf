
# RDS Module -
# Creates:
#   - Random suffix for unique name
#   - DB Subnet Group (multi-AZ)
#   - Security Group for DB
#   - Multi-AZ MySQL RDS Instance


# Generate random suffix to avoid name collisions
resource "random_id" "suffix" {
  byte_length = 4
}

# Create a DB subnet group using private subnets
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet-group-${random_id.suffix.hex}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "rds-subnet-group-${random_id.suffix.hex}"
    Environment = "sandbox"
    Project     = "EvalProject-Eda"
  }
}

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = var.vpc_id

  ingress {
    description = "Allow MySQL access from inside VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "rds-sg"
    Environment = "sandbox"
    Project     = "EvalProject-Eda"
  }
}

# Create Multi-AZ RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier             = "nginx-rds-${random_id.suffix.hex}"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 50
  username               = "admin"
  password               = "Password123!"
  multi_az               = true
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  backup_retention_period = 1
  deletion_protection    = false

  tags = {
    Name        = "nginx-rds-${random_id.suffix.hex}"
    Environment = "sandbox"
    Project     = "EvalProject-Eda"
  }
}

# Output for database endpoint
output "db_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
}
``
