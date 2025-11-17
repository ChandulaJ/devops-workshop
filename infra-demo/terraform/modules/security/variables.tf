variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "app_port" {
  description = "Application port number"
  type        = number
  default     = 3000
}

variable "enable_ssh_access" {
  description = "Enable SSH access to instances"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_alb_sg" {
  description = "Create security group for Application Load Balancer"
  type        = bool
  default     = false
}

variable "create_database_sg" {
  description = "Create security group for database"
  type        = bool
  default     = false
}

variable "database_port" {
  description = "Database port number"
  type        = number
  default     = 5432
}

variable "create_network_acl" {
  description = "Create Network ACL (additional security layer)"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnet IDs for Network ACL"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
