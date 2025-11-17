# Troubleshooting Guide

Common issues and their solutions when working with this infrastructure.

## Terraform Issues

### 1. Backend Initialization Errors

**Problem**: `Error loading state: AccessDenied: Access Denied`

**Cause**: S3 bucket doesn't exist or lacks permissions

**Solution**:
```bash
# Run the backend setup script
cd terraform/scripts
./setup-backend.sh

# Or manually create bucket
aws s3 mb s3://devops-workshop-terraform-state-dev --region us-east-1
```

### 2. State Lock Errors

**Problem**: `Error locking state: ConditionalCheckFailedException`

**Cause**: Previous Terraform run didn't release lock

**Solution**:
```bash
# View locks
aws dynamodb scan --table-name terraform-state-lock

# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

### 3. Module Not Found

**Problem**: `Module not found: module.networking`

**Cause**: Relative path issue or module not downloaded

**Solution**:
```bash
# Re-initialize to download modules
terraform init -upgrade

# Verify module path is correct in main.tf
source = "../../modules/networking"
```

### 4. Resource Already Exists

**Problem**: `Error creating VPC: VpcLimitExceeded`

**Cause**: AWS account limits reached

**Solution**:
```bash
# Check current VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]'

# Request limit increase or delete unused VPCs
terraform destroy  # in unused environments
```

### 5. Invalid CIDR Block

**Problem**: `Error: invalid CIDR address: 10.0.0/16`

**Cause**: Missing subnet mask or invalid format

**Solution**:
```hcl
# Correct format
vpc_cidr = "10.0.0.0/16"  # Not "10.0.0/16"

# Ensure no CIDR overlap between environments
dev:     10.0.0.0/16
staging: 10.1.0.0/16
prod:    10.2.0.0/16
```

### 6. Authentication Errors

**Problem**: `Error: error configuring Terraform AWS Provider: no valid credential sources`

**Solution**:
```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity

# Check environment variables
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
echo $AWS_REGION

# Use AWS profile
export AWS_PROFILE=your-profile
```

## Ansible Issues

### 1. SSH Connection Failures

**Problem**: `UNREACHABLE! => {"changed": false, "msg": "Failed to connect"}`

**Causes & Solutions**:

**Wrong SSH key**:
```bash
# Verify key permissions
chmod 600 ~/.ssh/id_rsa

# Test SSH manually
ssh -i ~/.ssh/id_rsa ubuntu@<ip>

# Update inventory if using different key
ansible_ssh_private_key_file=~/.ssh/custom_key
```

**Security group blocks SSH**:
```bash
# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Temporarily allow your IP
# Edit terraform.tfvars:
allowed_ssh_cidrs = ["YOUR_IP/32"]
terraform apply
```

**Wrong username**:
```ini
# Ubuntu AMI uses 'ubuntu'
ansible_user=ubuntu

# Amazon Linux uses 'ec2-user'
ansible_user=ec2-user
```

### 2. Python Not Found

**Problem**: `/usr/bin/python: not found`

**Solution**:
```ini
# In inventory or group_vars
ansible_python_interpreter=/usr/bin/python3
```

### 3. Permission Denied Errors

**Problem**: `Permission denied` when installing packages

**Solution**:
```yaml
# Use become for privilege escalation
- name: Install packages
  apt:
    name: nodejs
    state: present
  become: yes  # Add this

# Or run entire playbook with sudo
ansible-playbook playbook.yml --become
```

### 4. Module Not Found

**Problem**: `The module nodejs was not found`

**Solution**:
```bash
# Install required collections
ansible-galaxy collection install community.general

# Or use shell module
- name: Install Node.js
  shell: curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  become: yes
```

### 5. Idempotency Issues

**Problem**: Task shows "changed" on every run

**Solution**:
```yaml
# Add creates or when conditions
- name: Install something
  shell: ./install.sh
  args:
    creates: /usr/local/bin/something

# Or register and check
- name: Check if installed
  stat:
    path: /usr/local/bin/something
  register: binary

- name: Install if not exists
  shell: ./install.sh
  when: not binary.stat.exists
```

### 6. Inventory Not Found

**Problem**: `Unable to parse inventory/hosts as an inventory source`

**Solution**:
```bash
# Check file exists
ls -la ansible/inventory/dev/hosts

# Verify Terraform generated it
cd terraform/environments/dev
terraform apply  # Regenerates inventory

# Test inventory
ansible-inventory -i inventory/dev/hosts --list
```

## AWS-Specific Issues

### 1. Instance Fails to Start

**Problem**: Instance in "pending" state forever

**Diagnosis**:
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids <id>

# View system logs
aws ec2 get-console-output --instance-id <id>
```

**Common causes**:
- AMI not available in region
- Instance type not available in AZ
- Insufficient capacity
- User data script failure

### 2. NAT Gateway Connectivity Issues

**Problem**: Instances in private subnet can't reach internet

**Check**:
```bash
# Verify NAT gateway exists
aws ec2 describe-nat-gateways

# Check route table
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<vpc-id>"

# Ensure route points to NAT gateway
# 0.0.0.0/0 -> nat-xxxxx
```

### 3. Auto Scaling Group Not Scaling

**Problem**: ASG doesn't launch/terminate instances

**Check**:
```bash
# View ASG activity
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name>

# Check alarms
aws cloudwatch describe-alarms

# Verify metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=<asg-name> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

### 4. Load Balancer Health Checks Failing

**Problem**: Instances marked unhealthy by ALB

**Debug**:
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <arn>

# Common issues:
# - Security group doesn't allow ALB traffic
# - Health check path returns non-200
# - Application not listening on correct port
# - Health check interval too short

# Test manually
curl http://<instance-ip>:3000/health
```

## Application Issues

### 1. Application Won't Start

**Check systemd logs**:
```bash
ssh ubuntu@<ip>
sudo journalctl -u devops-workshop -f

# Common issues:
# - Port already in use
# - Missing dependencies
# - Environment variables not set
# - File permissions
```

### 2. Nginx Configuration Errors

**Test configuration**:
```bash
sudo nginx -t

# View error log
sudo tail -f /var/log/nginx/error.log

# Common issues:
# - Syntax errors in config
# - Upstream not responding
# - SSL certificate issues
```

### 3. Node.js Application Errors

**Debug**:
```bash
# Check Node version
node --version

# Test application directly
cd /opt/devops-workshop
sudo -u appuser PORT=3000 node app.js

# Check dependencies
npm list
npm audit

# View application logs
sudo journalctl -u devops-workshop --since "10 minutes ago"
```

## Debugging Commands

### Terraform
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
terraform apply

# View state
terraform state list
terraform state show <resource>

# Import existing resource
terraform import aws_instance.app i-xxxxx

# Refresh state
terraform refresh

# Target specific resource
terraform apply -target=module.networking
```

### Ansible
```bash
# Verbose output
ansible-playbook playbook.yml -vvv

# Check mode (dry run)
ansible-playbook playbook.yml --check

# Step through tasks
ansible-playbook playbook.yml --step

# Start at specific task
ansible-playbook playbook.yml --start-at-task="Install Node.js"

# Limit to specific hosts
ansible-playbook playbook.yml --limit app-1

# List tasks
ansible-playbook playbook.yml --list-tasks

# Syntax check
ansible-playbook playbook.yml --syntax-check
```

### AWS CLI
```bash
# Debug AWS CLI
aws ec2 describe-instances --debug

# Use different profile
aws ec2 describe-instances --profile staging

# Output as table
aws ec2 describe-instances --output table

# Query specific fields
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
  --output table
```

## Performance Issues

### 1. Slow Terraform Apply

**Optimize**:
```bash
# Parallelize operations
terraform apply -parallelism=20

# Target specific modules
terraform apply -target=module.compute

# Use local state for dev
# Comment out backend block in dev environment
```

### 2. Slow Ansible Playbook

**Optimize**:
```ini
# ansible.cfg
[defaults]
forks = 10              # Increase parallel execution
pipelining = True       # Reduce SSH overhead
gathering = smart       # Only gather facts when needed
fact_caching = jsonfile # Cache facts

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

## Cost Issues

### 1. Unexpected AWS Charges

**Investigate**:
```bash
# Check running instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,LaunchTime]'

# Check NAT gateways (expensive!)
aws ec2 describe-nat-gateways

# Check EBS volumes
aws ec2 describe-volumes \
  --filters "Name=status,Values=available"

# Check EIPs
aws ec2 describe-addresses --query 'Addresses[?AssociationId==null]'

# Enable cost allocation tags
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Environment
```

### 2. Reduce Costs

**Strategies**:
```bash
# Stop dev instances at night
aws ec2 stop-instances --instance-ids <ids>

# Use single NAT gateway in dev
# Edit terraform.tfvars:
enable_nat_gateway = true
single_nat_gateway = true

# Clean up unused resources
terraform destroy  # for dev/staging

# Release unused EIPs
aws ec2 release-address --allocation-id <eip-id>

# Delete old snapshots
aws ec2 describe-snapshots --owner-ids self
```

## Getting Help

### 1. Check Documentation
- Terraform: https://www.terraform.io/docs
- Ansible: https://docs.ansible.com
- AWS: https://docs.aws.amazon.com

### 2. Search Issues
- Terraform Registry: https://registry.terraform.io
- Ansible Galaxy: https://galaxy.ansible.com
- Stack Overflow with specific error messages

### 3. Enable Debug Mode
```bash
# Terraform
TF_LOG=DEBUG terraform apply

# Ansible
ansible-playbook playbook.yml -vvv

# AWS CLI
aws ec2 describe-instances --debug
```

### 4. Community Support
- Terraform Discuss: https://discuss.hashicorp.com
- Ansible Forum: https://forum.ansible.com
- AWS re:Post: https://repost.aws

---

**Still stuck?** Open an issue in the repository with:
- Full error message
- Terraform/Ansible version
- AWS region
- Steps to reproduce