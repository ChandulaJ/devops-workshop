# Staging Environment Configuration
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
    bucket         = "devops-workshop-terraform-state-staging"
    key            = "staging/terraform.tfstate"
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
      Environment = "staging"
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
    }
  }
}

locals {
  environment = "staging"
  name_prefix = "${var.project_name}-${local.environment}"
  
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  
  enable_nat_gateway      = true   # Enabled for staging
  single_nat_gateway      = true   # Cost optimization
  enable_flow_logs        = true   # Security monitoring
  flow_logs_retention_days = 7
  
  tags = local.common_tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  name_prefix       = local.name_prefix
  vpc_id            = module.networking.vpc_id
  vpc_cidr          = module.networking.vpc_cidr
  app_port          = var.app_port
  enable_ssh_access = true
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  
  create_alb_sg      = var.use_load_balancer
  create_database_sg = false
  create_network_acl = true  # Additional security layer
  subnet_ids         = module.networking.public_subnet_ids
  
  tags = local.common_tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  name_prefix         = local.name_prefix
  environment         = local.environment
  app_name            = var.project_name
  instance_type       = var.instance_type
  instance_count      = var.use_auto_scaling ? 0 : var.instance_count
  subnet_ids          = module.networking.public_subnet_ids
  security_group_ids  = [module.security.app_security_group_id]
  public_key_path     = var.public_key_path
  use_elastic_ip      = var.use_elastic_ip
  
  # Storage
  root_volume_size      = 30
  root_volume_type      = "gp3"
  enable_ebs_encryption = true
  
  # Monitoring
  enable_detailed_monitoring = true
  enable_cloudwatch_agent    = true
  
  # Auto Scaling
  use_auto_scaling          = var.use_auto_scaling
  asg_min_size              = var.asg_min_size
  asg_max_size              = var.asg_max_size
  asg_desired_capacity      = var.asg_desired_capacity
  enable_asg_metrics        = true
  enable_auto_scaling_policies = var.use_auto_scaling
  cpu_high_threshold        = 70
  cpu_low_threshold         = 30
  
  tags = local.common_tags
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../../templates/inventory.tpl", {
    instances = !var.use_auto_scaling && length(module.compute.instance_ids) > 0 ? [
      for idx in range(length(module.compute.instance_ids)) : {
        id         = module.compute.instance_ids[idx]
        public_ip  = module.compute.instance_public_ips[idx]
        private_ip = module.compute.instance_private_ips[idx]
      }
    ] : []
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
