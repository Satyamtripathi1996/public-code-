locals { name = var.project }

# SG for EC2: allow only from ALB on 80; egress via NAT
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

  # no inbound ssh from internet; if needed, use SSM/Bastion (not included by design)

  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }

  tags = merge(var.tags, { Name = "${local.name}-web-sg" })
}

# Amazon Linux 2 (us-east-1)
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name" values = ["amzn2-ami-hvm-*-x86_64-gp2"] }
}

# Launch Template with encrypted EBS and user_data (Nginx message)
resource "aws_launch_template" "lt" {
  name_prefix   = "${local.name}-lt-"
  image_id      = data.aws_ami.al2.id
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 10
      volume_type = "gp3"
      encrypted   = true
      kms_key_id  = var.kms_key_id
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.web.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    yum update -y
    yum install -y nginx
    systemctl enable nginx
    echo "<h1>Hello North, This side Eda.</h1>" > /usr/share/nginx/html/index.html
    systemctl start nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "${local.name}-web" })
  }
}

# Auto Scaling Group across private subnets
resource "aws_autoscaling_group" "asg" {
  name                = "${local.name}-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arn]

  health_check_type         = "EC2"
  health_check_grace_period = 120
  termination_policies      = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "${local.name}-web"
    propagate_at_launch = true
  }
}

# Scaling policies & CloudWatch alarms
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 65
  dimensions = { AutoScalingGroupName = aws_autoscaling_group.asg.name }
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.name}-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 40
  dimensions = { AutoScalingGroupName = aws_autoscaling_group.asg.name }
  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}

output "web_sg_id" { value = aws_security_group.web.id }
