output "vpc_id" {
  value = module.networking.vpc_id
}

output "instance_ids" {
  value = module.compute.instance_ids
}

output "instance_public_ips" {
  value = module.compute.instance_public_ips
}

output "autoscaling_group_name" {
  value = module.compute.autoscaling_group_name
}

output "ssh_commands" {
  value = var.use_auto_scaling ? [] : [
    for ip in module.compute.instance_public_ips :
    "ssh -i ~/.ssh/id_rsa ubuntu@${ip}"
  ]
}

output "application_urls" {
  value = var.use_auto_scaling ? [] : [
    for ip in module.compute.instance_public_ips :
    "http://${ip}:${var.app_port}"
  ]
}
