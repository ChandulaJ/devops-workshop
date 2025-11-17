[webservers]
%{ for idx, instance in instances ~}
app-${idx + 1} ansible_host=${use_eip ? eips[idx].public_ip : instance.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
%{ endfor ~}

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
