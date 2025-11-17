# Production Environment Configuration
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket         = "devops-workshop-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "DevOps-Workshop"
      Environment = "production"
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
      CostCenter  = "Engineering"
    }
  }
}

locals {
  environment = "production"
  name_prefix = "${var.project_name}-${local.environment}"
  
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Compliance  = "Required"
  }
}

# Networking Module - Production with high availability
module "networking" {
  source = "../../modules/networking"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  
  # Production features
  enable_nat_gateway       = true   # Required for private subnets
  single_nat_gateway       = false  # Multi-AZ for HA
  enable_flow_logs         = true   # Security compliance
  flow_logs_retention_days = 30     # Extended retention
  
  tags = local.common_tags
}

# Security Module - Production hardened
module "security" {
  source = "../../modules/security"

  name_prefix       = local.name_prefix
  vpc_id            = module.networking.vpc_id
  vpc_cidr          = module.networking.vpc_cidr
  app_port          = var.app_port
  enable_ssh_access = var.enable_ssh_access
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  
  # Production security features
  create_alb_sg      = true   # ALB required for production
  create_database_sg = var.create_database_sg
  create_network_acl = true   # Additional security layer
  subnet_ids         = module.networking.public_subnet_ids
  
  tags = local.common_tags
}

# Compute Module - Production with Auto Scaling
module "compute" {
  source = "../../modules/compute"

  name_prefix         = local.name_prefix
  environment         = local.environment
  app_name            = var.project_name
  instance_type       = var.instance_type
  instance_count      = 0  # Using ASG in production
  subnet_ids          = module.networking.private_subnet_cidrs != [] ? module.networking.private_subnet_ids : module.networking.public_subnet_ids
  security_group_ids  = [module.security.app_security_group_id]
  public_key_path     = var.public_key_path
  use_elastic_ip      = false  # Using ALB instead
  
  # Production storage
  root_volume_size      = 50
  root_volume_type      = "gp3"
  enable_ebs_encryption = true
  
  # Production monitoring
  enable_detailed_monitoring = true
  enable_cloudwatch_agent    = true
  require_imdsv2             = true  # Security best practice
  
  # Auto Scaling - Production
  use_auto_scaling             = true
  asg_min_size                 = var.asg_min_size
  asg_max_size                 = var.asg_max_size
  asg_desired_capacity         = var.asg_desired_capacity
  asg_health_check_type        = "ELB"  # Health checks via ALB
  enable_asg_metrics           = true
  enable_auto_scaling_policies = true
  cpu_high_threshold           = 70
  cpu_low_threshold            = 30
  
  tags = local.common_tags
}

# CloudWatch Alarms - Production monitoring
resource "aws_cloudwatch_metric_alarm" "instance_health" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${local.name_prefix}-instance-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Monitors EC2 instance health"
  
  dimensions = {
    AutoScalingGroupName = module.compute.autoscaling_group_name
  }

  tags = local.common_tags
}

# SNS Topic for alerts (Production)
resource "aws_sns_topic" "alerts" {
  count = var.enable_sns_alerts ? 1 : 0
  name  = "${local.name_prefix}-alerts"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.enable_sns_alerts && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Generate Ansible inventory (for initial setup, ASG instances managed separately)
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../../templates/inventory.tpl", {
    instances   = []  # ASG instances are dynamic
    environment = local.environment
  })
  filename = "${path.module}/../../../ansible/inventory/${local.environment}/hosts"
}

# Generate Ansible group vars
resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/../../templates/group_vars.tpl", {
    app_name     = var.project_name
    app_port     = var.app_port
    node_version = var.node_version
    environment  = local.environment
  })
  filename = "${path.module}/../../../ansible/inventory/${local.environment}/group_vars/all.yml"
}
