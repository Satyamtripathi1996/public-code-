locals {
  name = var.project
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${local.name}-db-subnets" })
}

# new code added rds security group allowed in ec2
resource "aws_security_group" "db" {
  name        = "${local.name}-db-sg"
  description = "Allow Postgres only from Web SG"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from Web SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.web_sg_id]
  }

  # No outbound — DB doesn’t need to talk out
  egress = []

  tags = merge(var.tags, { Name = "${local.name}-db-sg" })
}

resource "aws_db_instance" "this" {
  identifier                 = "${local.name}-postgres"
  engine                     = "postgres"
  instance_class             = "db.t3.micro"
  multi_az                   = true
  allocated_storage          = 20
  storage_type               = "gp3"
  storage_encrypted          = true

  username = var.db_username
  password = var.db_password
  db_name  = var.db_name
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period    = 7
  deletion_protection        = false
  apply_immediately          = true

  tags = merge(var.tags, { Name = "${local.name}-postgres" })
}

output "rds_sg_id" {
  value = aws_security_group.db.id
}
