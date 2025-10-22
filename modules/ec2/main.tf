resource "aws_security_group" "web" {
  name        = "${local.name}-web-sg"
  description = "Only ALB can reach web instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "ALB to Nginx"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-web-sg" })
}
