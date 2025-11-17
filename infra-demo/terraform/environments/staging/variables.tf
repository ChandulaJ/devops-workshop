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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.small"
}

variable "instance_count" {
  description = "Number of instances (when not using ASG)"
  type        = number
  default     = 2
}

variable "use_auto_scaling" {
  description = "Use Auto Scaling Group"
  type        = bool
  default     = false
}

variable "asg_min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 2
}

variable "use_elastic_ip" {
  description = "Use Elastic IPs"
  type        = bool
  default     = false
}

variable "use_load_balancer" {
  description = "Use Application Load Balancer"
  type        = bool
  default     = false
}

variable "public_key_path" {
  description = "SSH public key path"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

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

variable "allowed_ssh_cidrs" {
  description = "Allowed SSH CIDRs"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
