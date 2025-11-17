# Infrastructure as Code Demo - Terraform + Ansible

This project demonstrates how to use **Terraform** for infrastructure provisioning and **Ansible** for configuration management to deploy a Node.js application on AWS.

## 📋 Overview

This IaC example provisions:
- AWS VPC with public subnets across multiple availability zones
- EC2 instances for application hosting
- Security groups with appropriate firewall rules
- Automatic inventory generation for Ansible

Then uses Ansible to:
- Install and configure Node.js
- Deploy the application
- Set up Nginx as a reverse proxy
- Configure systemd service for the app
- Set up firewall rules with UFW

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│           AWS VPC (10.0.0.0/16)         │
│  ┌────────────────────────────────────┐ │
│  │  Public Subnet (Multi-AZ)          │ │
│  │  ┌──────────────────────────────┐  │ │
│  │  │  EC2 Instance                │  │ │
│  │  │  - Node.js App (Port 3000)   │  │ │
│  │  │  - Nginx (Port 80)           │  │ │
│  │  │  - Systemd Service           │  │ │
│  │  └──────────────────────────────┘  │ │
│  └────────────────────────────────────┘ │
│                                         │
│  Security Group:                        │
│  - Port 22 (SSH)                        │
│  - Port 80 (HTTP)                       │
│  - Port 3000 (App)                      │
└─────────────────────────────────────────┘
```

## 📁 Project Structure

```
infra-demo/
├── terraform/              # Terraform configuration
│   ├── main.tf            # Main infrastructure definitions
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   ├── terraform.tfvars.example
│   └── templates/         # Template files for Ansible
│       ├── inventory.tpl  # Ansible inventory template
│       └── vars.tpl       # Ansible variables template
│
├── ansible/               # Ansible configuration
│   ├── ansible.cfg        # Ansible settings
│   ├── playbook.yml       # Main deployment playbook
│   ├── verify.yml         # Verification playbook
│   ├── group_vars/
│   │   └── all.yml        # Group variables
│   ├── inventory/
│   │   └── hosts          # Inventory file (auto-generated)
│   └── templates/
│       ├── app.service.j2 # Systemd service template
│       └── nginx.conf.j2  # Nginx configuration template
│
└── scripts/               # Helper scripts
    ├── deploy.sh          # Full deployment script
    └── destroy.sh         # Cleanup script
```

## 🚀 Prerequisites

### Required Software

1. **Terraform** (>= 1.0)
   ```bash
   # Download from https://www.terraform.io/downloads.html
   terraform --version
   ```

2. **Ansible** (>= 2.10)
   ```bash
   # Install via pip
   pip install ansible
   ansible --version
   ```

3. **AWS CLI** (configured with credentials)
   ```bash
   # Install from https://aws.amazon.com/cli/
   aws configure
   ```

4. **SSH Key Pair**
   ```bash
   # Generate if you don't have one
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

### AWS Configuration

Ensure you have:
- AWS account with appropriate permissions
- AWS credentials configured (`~/.aws/credentials`)
- Default region set (`~/.aws/config`)

## 📝 Quick Start

### 1. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings:
```hcl
aws_region       = "us-east-1"
environment      = "dev"
instance_count   = 1
allowed_ssh_cidr = ["YOUR_IP/32"]  # Replace with your IP
```

### 2. Deploy Infrastructure with Terraform

```bash
# Initialize Terraform
cd terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

Terraform will:
- Create VPC, subnets, and networking components
- Launch EC2 instances
- Generate Ansible inventory automatically
- Output connection information

### 3. Deploy Application with Ansible

```bash
# Navigate to ansible directory
cd ../ansible

# Test connectivity
ansible webservers -m ping

# Deploy the application
ansible-playbook playbook.yml

# Verify deployment
ansible-playbook verify.yml
```

### 4. Access the Application

After successful deployment:

```bash
# Get the application URL from Terraform output
cd ../terraform
terraform output application_urls

# Or access via:
# http://<instance-public-ip>        (via Nginx on port 80)
# http://<instance-public-ip>:3000   (directly on port 3000)
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
