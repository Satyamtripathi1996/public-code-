locals { name = "${var.project}-bastion" }

resource "aws_security_group" "this" {
  name   = "${locals.name}-sg"
  vpc_id = var.vpc_id

  # SSH into bastion only from your /32 (or corp ranges)
  ingress {
    description = "SSH from your IP /32"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs_ssh
  }

  # Outbound open so bastion can yum/apt + SSH to private instances
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${locals.name}-sg" })
}

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name" values = ["amzn2-ami-hvm-*-x86_64-gp2"] }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.this.id]

  tags = merge(var.tags, { Name = locals.name })
}
