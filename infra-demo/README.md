# Production-Grade Infrastructure as Code with Terraform & Ansible

A comprehensive, production-ready Infrastructure as Code example demonstrating best practices for deploying applications on AWS using Terraform and Ansible with multi-environment support.

## 🎯 Key Features

### Infrastructure (Terraform)
- **Modular Architecture**: Reusable modules for networking, compute, and security
- **Multi-Environment**: Separate configurations for dev, staging, and production
- **Remote State**: S3 backend with DynamoDB locking
- **Auto Scaling**: Production-grade ASG with dynamic scaling policies
- **High Availability**: Multi-AZ deployment with NAT gateways
- **Security**: VPC Flow Logs, encrypted EBS, IMDSv2, Network ACLs
- **Monitoring**: CloudWatch metrics, alarms, and SNS notifications
- **IAM Best Practices**: Instance profiles with least-privilege permissions

### Configuration (Ansible)
- **Multi-Environment**: Environment-specific inventories and variables
- **Automated Deployment**: Complete application setup and configuration
- **Service Management**: Systemd integration with auto-restart
- **Reverse Proxy**: Nginx configuration with health checks
- **Idempotent**: Safe to run multiple times

## 🏗️ Architecture by Environment

### Development Environment
- **Cost**: ~$10-15/month
- 1x t3.micro instance
- Single NAT gateway
- Basic monitoring
- SSH access enabled

### Staging Environment
- **Cost**: ~$50-75/month
- 2x t3.small instances (or ASG)
- Multi-AZ with NAT gateways
- Enhanced monitoring & alarms
- VPC Flow Logs enabled

### Production Environment
- **Cost**: ~$200-500/month
- Auto Scaling (2-10x t3.medium)
- Multi-AZ redundancy
- Application Load Balancer
- Full security & compliance
- CloudWatch agent & SNS alerts
- SSH disabled (SSM only)

## 📁 Project Structure

```
infra-demo/
├── terraform/
│   ├── modules/                # Reusable modules
│   │   ├── networking/        # VPC, subnets, NAT, IGW
│   │   ├── compute/           # EC2, ASG, launch templates
│   │   └── security/          # Security groups, NACLs
│   ├── environments/          # Environment configs
│   │   ├── dev/              # Development
│   │   ├── staging/          # Staging
│   │   └── production/       # Production
│   ├── templates/            # Jinja templates
│   └── scripts/              # Helper scripts
│
├── ansible/
│   ├── playbook.yml          # Main deployment
│   ├── verify.yml            # Verification
│   ├── inventory/            # Per-environment
│   │   ├── dev/
│   │   ├── staging/
│   │   └── production/
│   └── templates/            # Service configs
│
└── docs/                     # Documentation
```

## 🚀 Quick Start

### Prerequisites

```bash
# Required tools
terraform --version  # >= 1.0
ansible --version    # >= 2.10
aws configure        # Configure AWS credentials
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa  # Generate SSH key if needed
```

### Step 1: Set Up Remote State (One-Time)

```bash
cd terraform/scripts
chmod +x setup-backend.sh
./setup-backend.sh
```

Creates S3 buckets and DynamoDB table for state management.

### Step 2: Deploy Infrastructure

```bash
# Deploy to development
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

terraform init
terraform plan
terraform apply
```

### Step 3: Deploy Application

```bash
cd ../../../ansible
ansible-playbook -i inventory/dev/hosts playbook.yml
```

### Step 4: Verify & Access

```bash
# Verify deployment
ansible-playbook -i inventory/dev/hosts verify.yml

# Get application URLs
cd ../terraform/environments/dev
terraform output application_urls
```

## 🔧 Using the Helper Scripts

### Full Deployment
```bash
cd infra-demo
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Cleanup Resources
```bash
chmod +x scripts/destroy.sh
./scripts/destroy.sh
```

## 📊 Terraform Outputs

After `terraform apply`, you'll see:

- **instance_public_ips**: Public IP addresses of EC2 instances
- **application_urls**: Direct links to access the application
- **ssh_connection_commands**: SSH commands to connect to instances
- **ansible_inventory_path**: Path to generated Ansible inventory

## 🔍 Ansible Playbooks

### Main Playbook (`playbook.yml`)
Installs and configures:
- Node.js runtime
- Application dependencies
- Systemd service
- Nginx reverse proxy
- UFW firewall

### Verification Playbook (`verify.yml`)
Checks:
- Service status
- Application health endpoint
- Nginx configuration
- Overall deployment health

## 🎯 Customization

### Modify Instance Count
```hcl
# In terraform.tfvars
instance_count = 2  # Deploy multiple instances
```

### Change Instance Type
```hcl
# In terraform.tfvars
instance_type = "t3.small"  # Use larger instance
```

### Use Elastic IPs
```hcl
# In terraform.tfvars
use_elastic_ip = true  # Allocate static IPs
```

### Customize Application Variables
```yaml
# In ansible/group_vars/all.yml
app_port: 3000
node_version: "18"
environment: "production"
```

## 🔐 Security Best Practices

1. **Restrict SSH Access**
   ```hcl
   allowed_ssh_cidr = ["YOUR_IP/32"]  # Not 0.0.0.0/0
   ```

2. **Use Secrets Management**
   - Store sensitive data in AWS Secrets Manager
   - Use Ansible Vault for encrypted variables

3. **Enable HTTPS**
   - Add SSL/TLS certificates
   - Configure Nginx with HTTPS

4. **Regular Updates**
   ```bash
   ansible webservers -m apt -a "update_cache=yes upgrade=dist" --become
   ```

## 🧪 Testing

### Test Ansible Connectivity
```bash
ansible webservers -m ping
```

### Test Application Health
```bash
curl http://<instance-ip>/health
```

### View Application Logs
```bash
ssh ubuntu@<instance-ip>
sudo journalctl -u devops-workshop -f
```

## 🔄 Updates and Redeployment

### Update Application Code
```bash
# Modify application files in jenkins-demo/
# Re-run Ansible
cd ansible
ansible-playbook playbook.yml
```

### Update Infrastructure
```bash
# Modify Terraform files
cd terraform
terraform plan
terraform apply
```

## 🐛 Troubleshooting

### Terraform Issues
```bash
# Refresh state
terraform refresh

# Destroy and recreate
terraform destroy
terraform apply
```

### Ansible Issues
```bash
# Increase verbosity
ansible-playbook playbook.yml -vvv

# Test specific host
ansible app-1 -m ping

# Check logs on server
ssh ubuntu@<ip> "sudo journalctl -u devops-workshop"
```

### Connection Issues
- Verify security group rules
- Check SSH key permissions (`chmod 600 ~/.ssh/id_rsa`)
- Ensure instance is in running state
- Verify AWS credentials

## 📚 Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)

## 🧹 Cleanup

To destroy all resources and avoid AWS charges:

```bash
cd terraform
terraform destroy
```

⚠️ This will permanently delete all resources created by Terraform.

## 📄 License

MIT License - See LICENSE file for details

---

**Happy Infrastructure as Coding! 🚀**
