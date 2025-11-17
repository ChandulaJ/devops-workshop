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

output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.main.key_name
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.app.id
}

output "launch_template_latest_version" {
  description = "Latest version of launch template"
  value       = aws_launch_template.app.latest_version
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = var.use_auto_scaling ? aws_autoscaling_group.app[0].name : null
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = var.use_auto_scaling ? aws_autoscaling_group.app[0].arn : null
}

output "iam_role_name" {
  description = "IAM role name for EC2 instances"
  value       = aws_iam_role.ec2.name
}

output "iam_role_arn" {
  description = "IAM role ARN for EC2 instances"
  value       = aws_iam_role.ec2.arn
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}
