output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = var.create_alb_sg ? aws_security_group.alb[0].id : null
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = var.create_database_sg ? aws_security_group.database[0].id : null
}

output "network_acl_id" {
  description = "Network ACL ID"
  value       = var.create_network_acl ? aws_network_acl.main[0].id : null
}
