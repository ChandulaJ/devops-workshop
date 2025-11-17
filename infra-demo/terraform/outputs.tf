output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.app[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = var.use_elastic_ip ? aws_eip.app[*].public_ip : aws_instance.app[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = aws_instance.app[*].private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.app.id
}

output "ssh_connection_commands" {
  description = "SSH commands to connect to instances"
  value = [
    for idx, instance in aws_instance.app : 
    "ssh -i ~/.ssh/id_rsa ubuntu@${var.use_elastic_ip ? aws_eip.app[idx].public_ip : instance.public_ip}"
  ]
}

output "application_urls" {
  description = "Application URLs"
  value = [
    for idx, instance in aws_instance.app :
    "http://${var.use_elastic_ip ? aws_eip.app[idx].public_ip : instance.public_ip}:3000"
  ]
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = "${path.module}/../ansible/inventory/hosts"
}
