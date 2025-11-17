# Security Module - Security Groups and Network ACLs
terraform {
  required_version = ">= 1.0"
}

# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  count       = var.create_alb_sg ? 1 : 0
  name        = "${var.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb-sg"
    }
  )
}

resource "aws_security_group_rule" "alb_http_ingress" {
  count             = var.create_alb_sg ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTP from internet"
}

resource "aws_security_group_rule" "alb_https_ingress" {
  count             = var.create_alb_sg ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTPS from internet"
}

resource "aws_security_group_rule" "alb_egress" {
  count             = var.create_alb_sg ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow all outbound traffic"
}

# Application Security Group
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-app-sg"
    }
  )
}

# HTTP from ALB or internet
resource "aws_security_group_rule" "app_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = var.create_alb_sg ? aws_security_group.alb[0].id : null
  cidr_blocks       = var.create_alb_sg ? null : ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = var.create_alb_sg ? "Allow HTTP from ALB" : "Allow HTTP from internet"
}

# Application port from ALB or internet
resource "aws_security_group_rule" "app_port_ingress" {
  type              = "ingress"
  from_port         = var.app_port
  to_port           = var.app_port
  protocol          = "tcp"
  source_security_group_id = var.create_alb_sg ? aws_security_group.alb[0].id : null
  cidr_blocks       = var.create_alb_sg ? null : ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = var.create_alb_sg ? "Allow app port from ALB" : "Allow app port from internet"
}

# SSH access (restricted)
resource "aws_security_group_rule" "app_ssh_ingress" {
  count             = var.enable_ssh_access ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.app.id
  description       = "Allow SSH from specified CIDRs"
}

# Egress rules
resource "aws_security_group_rule" "app_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound traffic"
}

# Database Security Group (if needed)
resource "aws_security_group" "database" {
  count       = var.create_database_sg ? 1 : 0
  name        = "${var.name_prefix}-db-sg"
  description = "Security group for database"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-sg"
    }
  )
}

resource "aws_security_group_rule" "database_ingress" {
  count                    = var.create_database_sg ? 1 : 0
  type                     = "ingress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.database[0].id
  description              = "Allow database access from application"
}

resource "aws_security_group_rule" "database_egress" {
  count             = var.create_database_sg ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.database[0].id
  description       = "Allow all outbound traffic"
}

# Network ACL (optional, additional layer of security)
resource "aws_network_acl" "main" {
  count      = var.create_network_acl ? 1 : 0
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Ingress rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Egress rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nacl"
    }
  )
}
