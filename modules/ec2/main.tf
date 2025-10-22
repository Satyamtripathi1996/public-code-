locals { name = var.project }

# SG: ALB → EC2:80 only. Egress open (outbound internet via NAT).
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

# Latest Amazon Linux 2 (HVM x86_64)
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Launch template with robust bootstrap + encrypted gp3 root
resource "aws_launch_template" "lt" {
  name_prefix             = "${local.name}-lt-"
  image_id                = data.aws_ami.al2.id
  instance_type           = var.instance_type
  update_default_version  = true   # LT changes roll forward automatically

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 10
      volume_type = "gp3"
      encrypted   = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.web.id]
  }

  # --- ROBUST USER-DATA (yum retries, idempotent) ---
  user_data = base64encode(<<'EOF'
#!/bin/bash
set -euxo pipefail

# Sometimes NAT/yum is slow; retry to avoid bootstrap failures
for i in {1..5}; do
  yum -y update && yum -y install nginx && break || sleep 10
done

systemctl enable nginx || true
echo "<h1>Hello North, This side Eda.</h1>" > /usr/share/nginx/html/index.html
systemctl restart nginx

# quick local health probe (optional)
curl -sI http://localhost/ || true
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "${local.name}-web" })
  }
}

# ASG with instance refresh (rolling) + grace period
resource "aws_autoscaling_group" "asg" {
  name                = "${local.name}-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Default"   # always use LT default
  }

  target_group_arns         = [var.target_group_arn]
  health_check_type         = "EC2"
  health_check_grace_period = 180

  # Any LT change ⇒ rolling replacement
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
    triggers = ["launch_template"]
  }

  termination_policies = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "${local.name}-web"
    propagate_at_launch = true
  }
}

# Scaling: up at 65%, down at 40%
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
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.asg.name }
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
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
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.asg.name }
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
}
