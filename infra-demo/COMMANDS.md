# Quick Reference Guide - Terraform & Ansible Commands

## Terraform Commands

### Initialize
```bash
cd terraform
terraform init
```

### Plan
```bash
terraform plan
terraform plan -out=tfplan
```

### Apply
```bash
terraform apply
terraform apply tfplan
terraform apply -auto-approve
```

### Destroy
```bash
terraform destroy
terraform destroy -auto-approve
```

### Output
```bash
terraform output
terraform output instance_public_ips
terraform output -json application_urls
```

### State
```bash
terraform state list
terraform state show aws_instance.app[0]
terraform refresh
```

### Format
```bash
terraform fmt
terraform validate
```

## Ansible Commands

### Ping
```bash
cd ansible
ansible webservers -m ping
ansible all -m ping
```

### Run Playbook
```bash
ansible-playbook playbook.yml
ansible-playbook playbook.yml -v       # Verbose
ansible-playbook playbook.yml -vvv     # Very verbose
ansible-playbook playbook.yml --check  # Dry run
```

### Ad-hoc Commands
```bash
# Check disk space
ansible webservers -m shell -a "df -h"

# Check memory
ansible webservers -m shell -a "free -m"

# Restart service
ansible webservers -m systemd -a "name=devops-workshop state=restarted" --become

# Update packages
ansible webservers -m apt -a "update_cache=yes upgrade=dist" --become
```

### Inventory
```bash
ansible-inventory --list
ansible-inventory --graph
```

### Facts
```bash
ansible webservers -m setup
ansible webservers -m setup -a "filter=ansible_distribution*"
```

## Combined Workflow

### Full Deployment
```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform apply

# 2. Wait for instances
sleep 30

# 3. Deploy application
cd ../ansible
ansible-playbook playbook.yml

# 4. Verify
ansible-playbook verify.yml
```

### Update Application
```bash
cd ansible
ansible-playbook playbook.yml --tags deploy
```

### Complete Teardown
```bash
cd terraform
terraform destroy -auto-approve
```

## Troubleshooting Commands

### Check Terraform State
```bash
terraform state list
terraform show
```

### Test Ansible Connection
```bash
ansible webservers -m ping -vvv
```

### Check Application Logs
```bash
ansible webservers -m shell -a "sudo journalctl -u devops-workshop -n 50" --become
```

### Check Service Status
```bash
ansible webservers -m systemd -a "name=devops-workshop" --become
```

### Manual SSH
```bash
# Get SSH command from Terraform
terraform output ssh_connection_commands

# Or manually
ssh -i ~/.ssh/id_rsa ubuntu@<instance-ip>
```

## Environment Variables

### Terraform
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
export AWS_PROFILE=your-profile
```

### Ansible
```bash
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_STDOUT_CALLBACK=yaml
```
