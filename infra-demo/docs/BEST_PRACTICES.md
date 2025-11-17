# Terraform & Ansible Best Practices

This document outlines the production-grade best practices implemented in this project.

## Terraform Best Practices

### 1. Modular Architecture

**Why**: Promotes reusability, maintainability, and testing

**Implementation**:
```
modules/
├── networking/  # Self-contained VPC module
├── compute/     # EC2/ASG module
└── security/    # Security groups module
```

**Benefits**:
- Modules can be versioned independently
- Easy to test in isolation
- Reusable across projects
- Clear separation of concerns

### 2. Environment Separation

**Why**: Prevents accidental changes to production

**Implementation**:
```
environments/
├── dev/         # Separate state, configs
├── staging/     # Mirrors production
└── production/  # Full security & HA
```

**Key Practices**:
- Different VPC CIDR ranges per environment
- Separate AWS accounts (recommended)
- Different feature flags (NAT gateway, monitoring, etc.)
- Progressive complexity (dev → staging → prod)

### 3. Remote State Management

**Why**: Team collaboration, state locking, disaster recovery

**Implementation**:
```hcl
backend "s3" {
  bucket         = "project-terraform-state-dev"
  key            = "dev/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

**Security**:
- Encryption at rest (AES-256)
- Versioning enabled
- State locking via DynamoDB
- Private S3 buckets
- Access logging

### 4. Variable Management

**Best Practices**:
```hcl
# variables.tf - Declarations with types & descriptions
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = can(regex("^t3\\.", var.instance_type))
    error_message = "Instance type must be t3 family"
  }
}

# terraform.tfvars - Actual values (not committed)
instance_type = "t3.small"

# terraform.tfvars.example - Template (committed)
instance_type = "t3.micro"  # Change to your needs
```

### 5. Resource Tagging

**Why**: Cost allocation, organization, automation

**Implementation**:
```hcl
default_tags {
  tags = {
    Project     = "DevOps-Workshop"
    Environment = "production"
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
  }
}
```

**Tagging Strategy**:
- Use `default_tags` in provider for consistency
- Add resource-specific tags as needed
- Include: Environment, Project, ManagedBy, Owner, CostCenter

### 6. Security Hardening

**Implemented Practices**:
- ✅ Encrypted EBS volumes
- ✅ IMDSv2 required (metadata service)
- ✅ VPC Flow Logs enabled
- ✅ Private subnets for compute (production)
- ✅ NAT gateways for outbound traffic
- ✅ Network ACLs (additional security layer)
- ✅ Least-privilege IAM roles
- ✅ Security group rules with descriptions
- ✅ SSH disabled in production (SSM instead)

### 7. High Availability

**Production Configuration**:
- Multi-AZ deployment (3 AZs)
- Redundant NAT gateways (one per AZ)
- Auto Scaling Group with health checks
- Target group health checks (with ALB)
- Automated recovery via ASG

### 8. Monitoring & Observability

**CloudWatch Integration**:
```hcl
# Detailed monitoring
enable_detailed_monitoring = true

# Custom metrics
enable_cloudwatch_agent = true

# Auto Scaling metrics
enable_asg_metrics = true

# Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  # Triggers scaling policies
}
```

### 9. Cost Optimization

**Dev Environment**:
- Single NAT gateway
- No Elastic IPs
- t3.micro instances
- Basic monitoring

**Production Trade-offs**:
- Multi-AZ NAT (reliability > cost)
- Reserved Instances / Savings Plans
- Right-sized based on metrics
- Scheduled scaling policies

### 10. Code Quality

**Practices**:
```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Security scanning
tfsec .

# Cost estimation
infracost breakdown --path .

# Documentation
terraform-docs markdown . > README.md
```

## Ansible Best Practices

### 1. Idempotency

**Why**: Safe to run multiple times

**Implementation**:
```yaml
- name: Install Node.js
  shell: |
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
  args:
    creates: /usr/bin/node  # Only runs if node doesn't exist
```

### 2. Environment Separation

**Directory Structure**:
```
inventory/
├── dev/
│   ├── hosts
│   └── group_vars/all.yml
├── staging/
│   ├── hosts
│   └── group_vars/all.yml
└── production/
    ├── hosts
    └── group_vars/all.yml
```

**Usage**:
```bash
ansible-playbook -i inventory/production/hosts playbook.yml
```

### 3. Secrets Management

**Best Practices**:
```yaml
# Use Ansible Vault
ansible-vault encrypt_string 'secret_value' --name 'db_password'

# Or AWS Secrets Manager
- name: Get secret from AWS
  set_fact:
    db_password: "{{ lookup('aws_secret', 'prod/db/password') }}"
```

### 4. Role-Based Organization

**Structure** (for larger projects):
```
roles/
├── common/          # Base configuration
├── nodejs/          # Node.js installation
├── app/             # Application deployment
└── monitoring/      # Monitoring setup
```

### 5. Error Handling

**Implementation**:
```yaml
- name: Start service
  systemd:
    name: "{{ app_name }}"
    state: started
  register: service_start
  retries: 3
  delay: 5
  until: service_start is success

- name: Verify service is running
  uri:
    url: "http://localhost:{{ app_port }}/health"
    status_code: 200
  retries: 10
  delay: 5
```

### 6. Performance Optimization

**Strategies**:
```ini
# ansible.cfg
[defaults]
gathering = smart                 # Only gather facts when needed
fact_caching = jsonfile          # Cache facts
pipelining = True                # Reduce SSH connections

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

### 7. Testing

**Pre-deployment**:
```bash
# Syntax check
ansible-playbook --syntax-check playbook.yml

# Dry run
ansible-playbook --check playbook.yml

# Test on dev first
ansible-playbook -i inventory/dev/hosts playbook.yml
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths:
      - 'infra-demo/terraform/**'

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/staging
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve tfplan

  ansible:
    needs: terraform
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Ansible
        run: |
          ansible-playbook -i inventory/staging/hosts playbook.yml
        working-directory: ansible
```

## Security Checklist

### Before Production

- [ ] Change default SSH CIDR from `0.0.0.0/0`
- [ ] Review all security group rules
- [ ] Enable MFA delete on S3 state buckets
- [ ] Set up AWS CloudTrail for audit logs
- [ ] Configure AWS Config for compliance
- [ ] Enable GuardDuty for threat detection
- [ ] Review IAM policies (least privilege)
- [ ] Set up SNS alerts
- [ ] Configure backup strategy
- [ ] Document incident response plan
- [ ] Test disaster recovery
- [ ] Enable AWS Organizations SCPs
- [ ] Set up cost alerts
- [ ] Review encryption at rest/transit

## Compliance Considerations

### SOC 2 / ISO 27001

- VPC Flow Logs (network monitoring)
- CloudWatch logging (audit trail)
- Encrypted storage (data protection)
- Access control (IAM policies)
- Change management (Terraform state history)

### HIPAA / PCI-DSS

- Dedicated VPC with private subnets
- Encryption at rest and in transit
- Access logging and monitoring
- Regular security assessments
- Automated patch management

## Documentation Standards

### Terraform Modules

Each module should include:
```
module/
├── main.tf         # Resources
├── variables.tf    # Input variables
├── outputs.tf      # Output values
├── README.md       # Usage documentation
└── examples/       # Example usage
```

### README Template

```markdown
# Module Name

## Description
Brief description of module purpose

## Usage
```hcl
module "example" {
  source = "./modules/example"
  # ... variables
}
```

## Inputs
| Name | Description | Type | Default |
|------|-------------|------|---------|
| vpc_cidr | VPC CIDR block | string | - |

## Outputs
| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
```

## Version Control

### Git Workflow

```bash
# Feature branch
git checkout -b feature/add-monitoring

# Make changes
# ... edit files ...

# Commit with conventional commits
git commit -m "feat(monitoring): add CloudWatch alarms"

# Pull request for review
# Terraform plan shown in PR
# Merge after approval
```

### Conventional Commits

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Testing
- `chore:` Maintenance

## Disaster Recovery

### Backup Strategy

1. **State Files**: S3 versioning enabled
2. **Infrastructure**: Terraform code in Git
3. **Data**: Application backups separate
4. **AMIs**: Regular snapshots
5. **Secrets**: AWS Secrets Manager / Parameter Store

### Recovery Procedure

```bash
# 1. Clone repository
git clone <repo-url>

# 2. Configure AWS credentials
aws configure

# 3. Restore infrastructure
cd terraform/environments/production
terraform init
terraform apply

# 4. Restore application
cd ../../../ansible
ansible-playbook -i inventory/production/hosts playbook.yml

# 5. Restore data (application-specific)
# ... database restore, file restore, etc.
```

## Continuous Improvement

### Regular Reviews

- **Weekly**: Review CloudWatch dashboards
- **Monthly**: Cost optimization review
- **Quarterly**: Security audit
- **Annually**: Disaster recovery test

### Metrics to Track

- Infrastructure drift (Terraform plan)
- Deployment frequency
- Mean time to recovery (MTTR)
- Change failure rate
- Cost per environment
- Security findings

---

**Remember**: Best practices evolve. Stay current with AWS, Terraform, and Ansible documentation!