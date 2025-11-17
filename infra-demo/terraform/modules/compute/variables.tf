variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances (when not using ASG)"
  type        = number
  default     = 1
}

variable "ami_id" {
  description = "AMI ID to use (leave empty for latest Ubuntu)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs for instance placement"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "public_key_content" {
  description = "SSH public key content (alternative to file path)"
  type        = string
  default     = ""
}

variable "use_elastic_ip" {
  description = "Allocate Elastic IPs for instances"
  type        = bool
  default     = false
}

# Storage options
variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "enable_ebs_encryption" {
  description = "Enable EBS encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for EBS encryption"
  type        = string
  default     = ""
}

# Security options
variable "require_imdsv2" {
  description = "Require IMDSv2 (metadata service v2)"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_agent" {
  description = "Install CloudWatch agent via user data"
  type        = bool
  default     = false
}

# Auto Scaling options
variable "use_auto_scaling" {
  description = "Use Auto Scaling Group instead of individual instances"
  type        = bool
  default     = false
}

variable "asg_min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 1
}

variable "asg_health_check_type" {
  description = "ASG health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "enable_asg_metrics" {
  description = "Enable ASG CloudWatch metrics"
  type        = bool
  default     = true
}

variable "enable_auto_scaling_policies" {
  description = "Enable auto scaling policies based on CPU"
  type        = bool
  default     = false
}

variable "cpu_high_threshold" {
  description = "CPU threshold for scaling up (%)"
  type        = number
  default     = 70
}

variable "cpu_low_threshold" {
  description = "CPU threshold for scaling down (%)"
  type        = number
  default     = 30
}

variable "target_group_arns" {
  description = "List of target group ARNs for load balancer"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
