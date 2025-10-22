locals { name = var.project }

# DB Subnet Group across private subnets
resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${local.name}-db-subnets" })
}

# SG: allow only Postgres from web SG
resource "aws_security_group" "db" {
  name   = "${local.name}-db-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "PostgreSQL from web tier only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.web_sg_id]
  }

  # outbound kept minimal—DB may talk out for patch repos/time/KMS
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }

  tags = merge(var.tags, { Name = "${local.name}-db-sg" })
}

resource "aws_db_instance" "this" {
  identifier              = "${local.name}-postgres"
  engine                  = "postgres"
  engine_version          = "15.5"           # stable
  instance_class          = "db.t3.micro"
  multi_az                = true
  allocated_storage       = 20
  storage_type            = "gp3"
  storage_encrypted       = true
  kms_key_id              = var.kms_key_id
  username                = var.db_username
  password                = var.db_password
  db_name                 = var.db_name
  port                    = 5432
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = false
  deletion_protection     = false
  backup_retention_period = 7
  copy_tags_to_snapshot   = true
  auto_minor_version_upgrade = true
  monitoring_interval     = 0   # can enable enhanced monitoring if needed
  apply_immediately       = true

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(var.tags, { Name = "${local.name}-postgres" })
}

output "db_endpoint" { value = aws_db_instance.this.address }
