resource "random_id" "suffix" {
  byte_length = 4
}

# --- Security Group ---
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

  tags = { Name = "nginx-sg" }
}

# --- Launch Template ---
resource "aws_launch_template" "nginx" {
  name_prefix   = "nginx-lt-"
  image_id      = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type = "t3.micro"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from Eda's Auto Scaling Nginx Server!</h1>" > /usr/share/nginx/html/index.html
  EOF
  )
}

# --- Auto Scaling Group ---
resource "aws_autoscaling_group" "nginx_asg" {
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.public_subnet_ids

  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }

  depends_on = [aws_security_group.web_sg]

  tag {
    key                 = "Name"
    value               = "nginx-asg"
    propagate_at_launch = true
  }
}

# --- Load Balancer ---
resource "aws_lb" "web_alb" {
  name               = "nginx-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = var.public_subnet_ids
}

# --- Target Group ---
resource "aws_lb_target_group" "web_tg" {
  name     = "nginx-tg-${random_id.suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# --- Listener ---
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# --- Scaling Policies ---
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "nginx-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.nginx_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "nginx-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.nginx_asg.name
}

# --- CloudWatch Alarms ---
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "nginx-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 65
  alarm_description   = "Scale up when CPU >= 65%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nginx_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "nginx-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 40
  alarm_description   = "Scale down when CPU <= 40%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nginx_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}
