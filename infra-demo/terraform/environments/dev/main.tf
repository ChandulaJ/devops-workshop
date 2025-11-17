# Development Environment Configuration
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

  # Remote state backend (recommended for production)
  backend "s3" {
    bucket         = "devops-workshop-terraform-state-dev"  # Change this to your bucket
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    # Uncomment after creating the backend resources
    # See: scripts/setup-backend.sh
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "DevOps-Workshop"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
    }
  }
}

# Local variables
locals {
  environment = "dev"
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

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
  
  enable_nat_gateway   = false  # Disabled for dev to save costs
  enable_flow_logs     = false  # Disabled for dev
  
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
  
  create_alb_sg      = false  # No ALB in dev
  create_database_sg = false  # No separate DB in dev
  create_network_acl = false  # Simplified security for dev
  
  tags = local.common_tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  name_prefix         = local.name_prefix
  environment         = local.environment
  app_name            = var.project_name
  instance_type       = var.instance_type
  instance_count      = var.instance_count
  subnet_ids          = module.networking.public_subnet_ids
  security_group_ids  = [module.security.app_security_group_id]
  public_key_path     = var.public_key_path
  use_elastic_ip      = false  # No EIP in dev
  
  # Storage
  root_volume_size       = 20
  root_volume_type       = "gp3"
  enable_ebs_encryption  = true
  
  # Monitoring (minimal for dev)
  enable_detailed_monitoring = false
  enable_cloudwatch_agent    = false
  
  # Auto Scaling (disabled for dev)
  use_auto_scaling = false
  
  tags = local.common_tags
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../../templates/inventory.tpl", {
    instances = module.compute.instance_ids != [] ? [
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
