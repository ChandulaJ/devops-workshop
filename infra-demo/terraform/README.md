# Terraform Infrastructure

This directory contains modular, multi-environment Terraform infrastructure following production best practices.

## 📂 Directory Structure

```
terraform/
├── modules/              # Reusable infrastructure modules
│   ├── networking/      # VPC, subnets, NAT gateways, routing
│   ├── compute/         # EC2 instances, Auto Scaling Groups, IAM
│   └── security/        # Security groups, Network ACLs
│
├── environments/        # Environment-specific configurations
│   ├── dev/            # Development environment
│   ├── staging/        # Staging environment
│   └── production/     # Production environment
│
├── templates/          # Template files for dynamic generation
│   ├── inventory.tpl   # Ansible inventory template
│   └── group_vars.tpl  # Ansible group_vars template
│
└── scripts/            # Helper scripts
    ├── setup-backend.sh      # Set up S3/DynamoDB backend
    ├── destroy-backend.sh    # Clean up backend resources
    ├── deploy.sh             # Deploy environment
    └── destroy.sh            # Destroy environment
```

## 🚀 Quick Start

### 1. Set Up Remote State Backend (One-Time Setup)

```bash
cd scripts
./setup-backend.sh
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking

### 2. Deploy an Environment

```bash
# Navigate to the environment you want to deploy
cd environments/dev

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your values

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply changes
terraform apply
```

### 3. Deploy Application with Ansible

After Terraform creates the infrastructure, it auto-generates Ansible inventory files.

```bash
cd ../../../ansible
ansible-playbook -i inventory/dev/hosts playbook.yml
```

## 🎯 Environment Comparison

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Cost** | ~$10-15/month | ~$50-75/month | ~$200-500/month |
| **Instance Type** | t3.micro | t3.small | t3.medium |
| **High Availability** | No | Partial | Yes (Multi-AZ) |
| **Auto Scaling** | No | Optional | Yes (2-10 instances) |
| **NAT Gateway** | Optional | Yes (single) | Yes (Multi-AZ) |
| **VPC Flow Logs** | No | Yes | Yes (30-day retention) |
| **CloudWatch Alarms** | Basic | Enhanced | Full + SNS alerts |
| **SSH Access** | Enabled | Enabled | Disabled (SSM only) |
| **Private Subnets** | No | Yes | Yes |
| **Network ACLs** | No | Yes | Yes |

## 📋 Common Commands

### Working with Environments

```bash
# Initialize environment (first time)
cd environments/<env>
terraform init

# See what will change
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List all resources
terraform state list
```

### Using Helper Scripts

```bash
# Deploy with script
cd scripts
./deploy.sh <environment>  # dev, staging, or production

# Destroy with script
./destroy.sh <environment>
```

## 🔧 Module Usage

Modules are reusable components called by environment configurations. **Never run Terraform directly in module directories.**

### Networking Module
```hcl
module "networking" {
  source = "../../modules/networking"
  
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  # ... other variables
}
```

### Compute Module
```hcl
module "compute" {
  source = "../../modules/compute"
  
  environment   = var.environment
  vpc_id        = module.networking.vpc_id
  subnet_ids    = module.networking.public_subnet_ids
  # ... other variables
}
```

### Security Module
```hcl
module "security" {
  source = "../../modules/security"
  
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  # ... other variables
}
```

## 🔐 Remote State Backend

Each environment is configured to use S3 for remote state storage:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-<your-project>"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

**Important**: 
- Uncomment the backend block in each environment's `main.tf` after running `setup-backend.sh`
- Each environment uses a different `key` path
- State is encrypted at rest

## 📝 Variable Configuration

### Variables Priority (highest to lowest):

1. Command line: `-var="key=value"`
2. `terraform.tfvars` (automatically loaded)
3. `*.auto.tfvars` (automatically loaded)
4. Environment variables: `TF_VAR_name`
5. Default values in `variables.tf`

### Example terraform.tfvars:

```hcl
aws_region = "us-east-1"
environment = "dev"
project_name = "myapp"

vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

instance_type = "t3.micro"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
```

## 🛡️ Security Best Practices

1. **Never commit sensitive files**:
   - `terraform.tfvars` (gitignored)
   - `*.tfstate` (gitignored)
   - SSH keys (gitignored)

2. **Use remote state**:
   - Enable versioning on S3 bucket
   - Enable encryption
   - Use DynamoDB locking

3. **Follow least privilege**:
   - Use IAM roles instead of access keys
   - Enable IMDSv2 on EC2 instances
   - Use AWS Secrets Manager for secrets

4. **Enable monitoring**:
   - VPC Flow Logs (staging/production)
   - CloudWatch alarms
   - SNS notifications for alerts

## 🔄 Workflow

### Making Infrastructure Changes

1. Edit module or environment files
2. Run `terraform fmt` to format
3. Run `terraform validate` to check syntax
4. Run `terraform plan` to preview changes
5. Review the plan carefully
6. Run `terraform apply` to apply changes
7. Verify in AWS console

### Adding New Environments

```bash
# Copy an existing environment
cp -r environments/dev environments/test

# Edit configuration
cd environments/test
nano terraform.tfvars

# Update backend key in main.tf
# Change: key = "environments/test/terraform.tfstate"

# Deploy
terraform init
terraform apply
```

### Updating Modules

When you update a module, all environments using it will be affected:

```bash
# After changing a module
cd environments/dev
terraform get -update  # Update module references
terraform plan         # See what changed
```

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Best Practices Guide](../docs/BEST_PRACTICES.md)
- [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)
- [Complete Structure](../docs/STRUCTURE.md)

## ⚠️ Important Notes

1. **Always work from environment directories**, not the root or module directories
2. **Run `setup-backend.sh` once** before using any environment
3. **Review plans carefully** before applying, especially in production
4. **Test in dev first** before applying to staging/production
5. **Keep modules generic** and environment-specific config in environment directories

## 🆘 Troubleshooting

### "Backend initialization required"
```bash
terraform init -reconfigure
```

### "Lock table does not exist"
```bash
cd scripts
./setup-backend.sh
```

### "Module not found"
```bash
terraform get -update
terraform init
```

### State file conflicts
```bash
# Force unlock (use carefully!)
terraform force-unlock <lock-id>
```

---

**Remember**: This is a production-grade structure. Always test in `dev` first! 🚀
