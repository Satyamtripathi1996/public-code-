output "bastion_public_ip" { value = aws_instance.this.public_ip }
output "bastion_sg_id"     { value = aws_security_group.this.id }
