#!/bin/bash
set -e

# User data script for EC2 instances
echo "Starting user data script execution..."

# Update system packages
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    python3 \
    python3-pip \
    curl \
    wget \
    unzip \
    git \
    jq

# Install AWS CLI v2
if ! command -v aws &> /dev/null; then
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
fi

# Install CloudWatch Agent (if enabled)
%{ if cloudwatch_enabled ~}
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/${app_name}",
            "log_stream_name": "{instance_id}/syslog"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${app_name}/${environment}",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
%{ endif ~}

# Install SSM Agent (usually pre-installed on Ubuntu AMIs, but ensure it's running)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Set hostname
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
hostnamectl set-hostname "${app_name}-${environment}-$INSTANCE_ID"

# Create application directory
mkdir -p /opt/${app_name}

# Write environment info
cat > /etc/environment.d/app.conf <<EOF
APP_NAME=${app_name}
ENVIRONMENT=${environment}
INSTANCE_ID=$INSTANCE_ID
EOF

echo "User data script completed successfully"
