# Quick Start Guide - Infrastructure as Code

Get started with deploying production-grade infrastructure in 15 minutes!

## ⚡ Prerequisites (5 minutes)

### Install Required Tools

**macOS**:
```bash
brew install terraform ansible awscli
```

**Linux**:
```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Ansible
pip3 install ansible

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Windows** (use WSL2):
```bash
# Inside WSL2 Ubuntu
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
pip3 install ansible
```

### Configure AWS

```bash
aws configure
# AWS Access Key ID: YOUR_KEY
# AWS Secret Access Key: YOUR_SECRET
# Default region: us-east-1
# Default output format: json

# Verify
aws sts get-caller-identity
```

### Generate SSH Key

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
# Press Enter for default location and no passphrase
```

## 🚀 Deploy Development Environment (10 minutes)

### Step 1: Set Up State Backend (2 minutes)

```bash
cd infra-demo/terraform/scripts
chmod +x *.sh
./setup-backend.sh
```

This creates:
- S3 buckets for Terraform state (one per environment)
- DynamoDB table for state locking
- Encryption enabled

### Step 2: Configure Development Environment (1 minute)

```bash
cd ../environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
# Minimal changes needed:
allowed_ssh_cidrs = ["YOUR_IP/32"]  # Replace with your IP
```

Get your IP:
```bash
curl ifconfig.me
# Use: ["X.X.X.X/32"]
```

### Step 3: Deploy Infrastructure (3 minutes)

```bash
# Initialize Terraform
terraform init

# See what will be created
terraform plan

# Create infrastructure
terraform apply
# Type 'yes' when prompted
```

This creates:
- VPC with public subnets
- 1x t3.micro EC2 instance
- Security groups
- SSH key pair
- Ansible inventory (auto-generated)

### Step 4: Deploy Application (3 minutes)

```bash
# Wait 30 seconds for instance to be ready
sleep 30

cd ../../../ansible

# Test connectivity
ansible -i inventory/dev/hosts webservers -m ping

# Deploy application
ansible-playbook -i inventory/dev/hosts playbook.yml

# Verify deployment
ansible-playbook -i inventory/dev/hosts verify.yml
```

### Step 5: Access Application (1 minute)

```bash
cd ../terraform/environments/dev

# Get URLs
terraform output application_urls

# Example output:
# [
#   "http://54.123.45.67:3000"
# ]
```

Open URL in browser to see the application! 🎉

## 🏢 Deploy Staging Environment (15 minutes)

Similar to dev, but with production-like features:

```bash
cd terraform/environments/staging

# Configure
cp terraform.tfvars.example terraform.tfvars
# Edit with your settings

# Deploy
terraform init
terraform apply

# Configure application
cd ../../../ansible
ansible-playbook -i inventory/staging/hosts playbook.yml
```

Staging includes:
- 2x t3.small instances
- NAT gateway for private subnets
- VPC Flow Logs
- Enhanced monitoring
- Network ACLs

## 🎯 Environment Comparison

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Cost/month** | $10-15 | $50-75 | $200-500 |
| **Instances** | 1x t3.micro | 2x t3.small | ASG (2-10x t3.medium) |
| **High Availability** | No | Partial | Yes (Multi-AZ) |
| **NAT Gateway** | Single | Single | Multi-AZ |
| **Monitoring** | Basic | Enhanced | Full |
| **Auto Scaling** | No | Optional | Yes |
| **Load Balancer** | No | Optional | Yes |
| **VPC Flow Logs** | No | Yes | Yes |
| **SSH Access** | Yes | Yes | No (SSM only) |

## 📋 Next Steps

### Learn More
- [ ] Read `docs/BEST_PRACTICES.md` - Understanding production patterns
- [ ] Read `docs/TROUBLESHOOTING.md` - Solve common issues
- [ ] Explore Terraform modules - See how infrastructure is organized
- [ ] Review Ansible playbooks - Understand configuration management

### Customize
- [ ] Add database module (RDS/DynamoDB)
- [ ] Implement Application Load Balancer
- [ ] Set up CloudFront CDN
- [ ] Add Route53 for DNS
- [ ] Configure monitoring dashboards

### Production Readiness
- [ ] Set up AWS Organizations & SCPs
- [ ] Enable AWS Config rules
- [ ] Configure AWS GuardDuty
- [ ] Set up AWS CloudTrail
- [ ] Implement secrets rotation
- [ ] Add backup automation
- [ ] Create runbook for incidents
- [ ] Test disaster recovery

## 🧹 Cleanup

### Destroy Single Environment
```bash
cd terraform/environments/dev
terraform destroy
# Type 'yes' when prompted
```

### Destroy All Environments
```bash
cd terraform/scripts
./destroy.sh dev
./destroy.sh staging
./destroy.sh production
```

### Remove State Backend (Final Cleanup)
```bash
cd terraform/scripts
./destroy-backend.sh
# Type 'DESTROY' when prompted
```

⚠️ **Warning**: This permanently deletes all state history!

## 🛠️ Common Commands

### Terraform
```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# List resources
terraform state list

# View outputs
terraform output

# Destroy everything
terraform destroy

# Format code
terraform fmt -recursive

# Validate syntax
terraform validate
```

### Ansible
```bash
# Ping hosts
ansible -i inventory/dev/hosts webservers -m ping

# Run playbook
ansible-playbook -i inventory/dev/hosts playbook.yml

# Dry run
ansible-playbook -i inventory/dev/hosts playbook.yml --check

# Verbose output
ansible-playbook -i inventory/dev/hosts playbook.yml -vvv

# Verify deployment
ansible-playbook -i inventory/dev/hosts verify.yml

# Run specific tasks
ansible-playbook -i inventory/dev/hosts playbook.yml --tags "deploy"
```

### AWS CLI
```bash
# List instances
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"

# Check VPCs
aws ec2 describe-vpcs

# View logs
aws logs tail /aws/ec2/devops-workshop --follow

# SSM session (if SSH disabled)
aws ssm start-session --target <instance-id>
```

## 📊 Monitoring

### View Metrics
```bash
# CloudWatch dashboard
aws cloudwatch list-dashboards

# Get metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<instance-id> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

### View Logs
```bash
# Application logs
ssh -i ~/.ssh/id_rsa ubuntu@<instance-ip>
sudo journalctl -u devops-workshop -f

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# System logs
sudo tail -f /var/log/syslog
```

## 🔐 Security Tips

### Before Going to Production
1. **Change SSH CIDR**: From `0.0.0.0/0` to your IP
2. **Enable MFA**: On AWS root account
3. **Review IAM policies**: Principle of least privilege
4. **Enable CloudTrail**: For audit logging
5. **Set up billing alerts**: Prevent cost surprises
6. **Encrypt secrets**: Use Ansible Vault or AWS Secrets Manager
7. **Regular updates**: Keep AMIs and packages current
8. **Backup strategy**: Regular snapshots and state backups

## 💡 Tips & Tricks

### Speed Up Development
```bash
# Use local state for dev (faster)
# Comment out backend block in dev/main.tf

# Parallel Terraform operations
terraform apply -parallelism=20

# Ansible fact caching (edit ansible.cfg)
gathering = smart
fact_caching = jsonfile
```

### Cost Saving
```bash
# Stop dev instances when not in use
aws ec2 stop-instances --instance-ids $(terraform output -json instance_ids | jq -r '.[]')

# Start them again
aws ec2 start-instances --instance-ids $(terraform output -json instance_ids | jq -r '.[]')

# Or schedule with Lambda/EventBridge
```

### Debugging
```bash
# Terraform debug
TF_LOG=DEBUG terraform apply

# Ansible debug
ANSIBLE_DEBUG=1 ansible-playbook playbook.yml -vvv

# AWS CLI debug
aws ec2 describe-instances --debug
```

## 🎓 Learning Resources

### Official Documentation
- [Terraform](https://www.terraform.io/docs)
- [Ansible](https://docs.ansible.com)
- [AWS](https://docs.aws.amazon.com)

### Tutorials
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [AWS Well-Architected](https://aws.amazon.com/architecture/well-architected/)

### Community
- [Terraform Discuss](https://discuss.hashicorp.com/c/terraform-core)
- [Ansible Forum](https://forum.ansible.com)
- [AWS re:Post](https://repost.aws)

## ❓ FAQ

**Q: How much will this cost?**  
A: Dev environment: ~$10-15/month. Stop instances when not in use to save costs.

**Q: Can I use this in production?**  
A: Yes! Review security settings and read BEST_PRACTICES.md first.

**Q: How do I add a database?**  
A: Create a database module or use AWS RDS. See customization examples.

**Q: Can I use a different cloud provider?**  
A: Yes, but you'll need to modify Terraform modules for Azure/GCP.

**Q: How do I roll back changes?**  
A: Use Terraform state history or restore from S3 versioning.

---

**Need Help?** Check `docs/TROUBLESHOOTING.md` or open an issue!