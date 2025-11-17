# Compute Module - EC2 Instances and Auto Scaling
terraform {
  required_version = ">= 1.0"
}

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${var.name_prefix}-key"
  public_key = var.public_key_content != "" ? var.public_key_content : file(var.public_key_path)

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-key"
    }
  )
}

# IAM Role for EC2 (Production best practice)
resource "aws_iam_role" "ec2" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = var.tags
}

# Attach SSM policy for Systems Manager access (Production best practice)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch policy for logging
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Launch Template (Production best practice over individual instances)
resource "aws_launch_template" "app" {
  name_prefix            = "${var.name_prefix}-"
  image_id               = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = var.enable_ebs_encryption
      kms_key_id            = var.enable_ebs_encryption && var.kms_key_id != "" ? var.kms_key_id : null
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.require_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment   = var.environment
    app_name      = var.app_name
    cloudwatch_enabled = var.enable_cloudwatch_agent
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-instance"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-volume"
      }
    )
  }

  tags = var.tags
}

# EC2 Instances (for simple deployments)
resource "aws_instance" "app" {
  count = var.use_auto_scaling ? 0 : var.instance_count

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  subnet_id = var.subnet_ids[count.index % length(var.subnet_ids)]

  tags = merge(
    var.tags,
    {
      Name  = "${var.name_prefix}-${count.index + 1}"
      Index = count.index + 1
    }
  )
}

# Elastic IPs (optional)
resource "aws_eip" "app" {
  count    = var.use_auto_scaling ? 0 : (var.use_elastic_ip ? var.instance_count : 0)
  instance = aws_instance.app[count.index].id
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eip-${count.index + 1}"
    }
  )
}

# Auto Scaling Group (Production best practice)
resource "aws_autoscaling_group" "app" {
  count               = var.use_auto_scaling ? 1 : 0
  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  health_check_type   = var.asg_health_check_type
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = var.target_group_arns

  enabled_metrics = var.enable_asg_metrics ? [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ] : []

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-asg-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  count                  = var.use_auto_scaling && var.enable_auto_scaling_policies ? 1 : 0
  name                   = "${var.name_prefix}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app[0].name
}

resource "aws_autoscaling_policy" "scale_down" {
  count                  = var.use_auto_scaling && var.enable_auto_scaling_policies ? 1 : 0
  name                   = "${var.name_prefix}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app[0].name
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.use_auto_scaling && var.enable_auto_scaling_policies ? 1 : 0
  alarm_name          = "${var.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_high_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app[0].name
  }

  alarm_description = "Scale up if CPU exceeds ${var.cpu_high_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_up[0].arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count               = var.use_auto_scaling && var.enable_auto_scaling_policies ? 1 : 0
  alarm_name          = "${var.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_low_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app[0].name
  }

  alarm_description = "Scale down if CPU below ${var.cpu_low_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_down[0].arn]

  tags = var.tags
}
