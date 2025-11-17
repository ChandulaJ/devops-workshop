output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = module.compute.autoscaling_group_arn
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = module.security.app_security_group_id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.security.alb_security_group_id
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = module.compute.launch_template_id
}

output "iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = module.compute.iam_role_arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = var.enable_sns_alerts ? aws_sns_topic.alerts[0].arn : null
}
