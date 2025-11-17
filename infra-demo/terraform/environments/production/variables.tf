variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devops-workshop"
}

# Networking
variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Compute
variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.medium"
}

# Auto Scaling
variable "asg_min_size" {
  description = "ASG min size"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG max size"
  type        = number
  default     = 10
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 3
}

# Security
variable "enable_ssh_access" {
  description = "Enable SSH (should be false in production)"
  type        = bool
  default     = false
}

variable "allowed_ssh_cidrs" {
  description = "Allowed SSH CIDRs (use VPN or bastion host)"
  type        = list(string)
  default     = []
}

variable "create_database_sg" {
  description = "Create database security group"
  type        = bool
  default     = false
}

# Monitoring
variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_sns_alerts" {
  description = "Enable SNS email alerts"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
  default     = ""
}

# Application
variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3000
}

variable "node_version" {
  description = "Node.js version"
  type        = string
  default     = "18"
}

variable "public_key_path" {
  description = "SSH public key path"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
