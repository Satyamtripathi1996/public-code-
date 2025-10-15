resource "aws_security_group" "web_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "nginx" {
  name_prefix   = "nginx-lt-"
  image_id      = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = "t3.micro"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from Auto Scaling Nginx</h1>" > /usr/share/nginx/html/index.html
  EOF
  )

  security_group_names = [aws_security_group.web_sg.name]
}

resource "aws_autoscaling_group" "nginx_asg" {
  desired_capacity     = 1
  min_size             = 1
  max_size             = 3
  vpc_zone_identifier  = var.public_subnet_ids
  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }
}

resource "aws_lb" "web_alb" {
  name               = "nginx-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "web_tg" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}
