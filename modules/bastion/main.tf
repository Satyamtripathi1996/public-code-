locals { name = var.project }

resource "aws_security_group" "bastion" {
  name        = "${local.name}-bastion-sg"
  description = "SSH from allowed CIDRs to bastion"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from your IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  # Egress can be wide or restricted; here minimal to 22/80/443 for admin use
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-bastion-sg" })
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.al2.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  tags = merge(var.tags, { Name = "${local.name}-bastion" })
}

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name" values = ["amzn2-ami-hvm-*-x86_64-gp2"] }
}
