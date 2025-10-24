locals {
  name = var.project
}

# ──────────────────────────────────────────────────────────────────────────────
# Security Group: allow ALB -> EC2:80 only
# Outbound is restricted (HTTPS to internet via NAT; Postgres to RDS SG)
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "web" {
  name        = "${local.name}-web-sg"
  description = "Only ALB can reach web instances"
  vpc_id      = var.vpc_id

  # Inbound: ALB to Nginx (port 80)
  ingress {
    description     = "ALB to Nginx"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Outbound: allow HTTPS (for patching/repos) via NAT
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: allow Postgres to RDS (scope to DB SG; avoids 0.0.0.0/0)
  egress {
    description     = "Allow outbound Postgres to RDS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.db_sg_id]
  }

  tags = merge(var.tags, { Name = "${local.name}-web-sg" })
}

# ──────────────────────────────────────────────────────────────────────────────
# Latest Amazon Linux 2 AMI (HVM x86_64)
# ──────────────────────────────────────────────────────────────────────────────
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Launch Template: encrypted gp3 root, monitoring on, robust bootstrap
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_launch_template" "lt" {
  name_prefix            = "${local.name}-lt-"
  image_id               = data.aws_ami.al2.id
  instance_type          = var.instance_type
  update_default_version = true

  monitoring {
    enabled = true
  }

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

  # ---------- USER DATA ----------
  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euxo pipefail

    # Retry YUM (handle transient NAT/repo issues)
    for i in {1..5}; do
      yum -y update && break || sleep 10
    done

    # Install Nginx via Amazon Linux Extras (AL2)
    amazon-linux-extras enable nginx1
    yum clean metadata
    yum -y install nginx

    systemctl enable nginx
    echo "<h1>Hello North, This side Eda.</h1>" > /usr/share/nginx/html/index.html
    systemctl restart nginx

    # Local probe so ALB health check passes immediately
    curl -sI http://localhost/ || true
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "${local.name}-web" })
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Auto Scaling Group: ALB target, ELB health check, rolling instance refresh
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_autoscaling_group" "asg" {
  name                = "${local.name}-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Default"   # always track latest LT default version
  }

  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"   # use ALB health
  health_check_grace_period = 180

  # Rolling refresh when LT changes
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

# ──────────────────────────────────────────────────────────────────────────────
# Scaling policies + CloudWatch alarms (≥65% up, ≤40% down)
# ──────────────────────────────────────────────────────────────────────────────
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
  treat_missing_data  = "notBreaching"
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
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
}
