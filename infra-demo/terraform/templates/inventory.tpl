[webservers]
%{ for idx, instance in instances ~}
app-${idx + 1} ansible_host=${instance.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa private_ip=${instance.private_ip}
%{ endfor ~}

%{ if length(instances) == 0 ~}
# No instances available - using Auto Scaling Group
# Use dynamic inventory or AWS Systems Manager for ASG instances
%{ endif ~}

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
environment=${environment}
