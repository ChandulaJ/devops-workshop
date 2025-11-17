# AWS Region
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Project Configuration
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devops-workshop"
}

# Networking
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = []  # No private subnets in dev
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Compute
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
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

# Security
variable "allowed_ssh_cidrs" {
  description = "Allowed CIDR blocks for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production!
}
