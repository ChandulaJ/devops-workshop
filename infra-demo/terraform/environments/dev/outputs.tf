# Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

# Compute Outputs
output "instance_ids" {
  description = "EC2 instance IDs"
  value       = module.compute.instance_ids
}

output "instance_public_ips" {
  description = "Instance public IPs"
  value       = module.compute.instance_public_ips
}

output "instance_private_ips" {
  description = "Instance private IPs"
  value       = module.compute.instance_private_ips
}

# Security Outputs
output "app_security_group_id" {
  description = "Application security group ID"
  value       = module.security.app_security_group_id
}

# Connection Information
output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = [
    for ip in module.compute.instance_public_ips :
    "ssh -i ~/.ssh/id_rsa ubuntu@${ip}"
  ]
}

output "application_urls" {
  description = "Application URLs"
  value = [
    for ip in module.compute.instance_public_ips :
    "http://${ip}:${var.app_port}"
  ]
}

output "nginx_urls" {
  description = "Nginx URLs (after Ansible deployment)"
  value = [
    for ip in module.compute.instance_public_ips :
    "http://${ip}"
  ]
}

# Ansible Integration
output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}

output "ansible_command" {
  description = "Command to run Ansible playbook"
  value       = "cd ../../../ansible && ansible-playbook -i inventory/dev/hosts playbook.yml"
}
