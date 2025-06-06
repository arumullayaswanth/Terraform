# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# -----------------------
# Key Pair
# -----------------------
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"                # Name of the key pair
  public_key = file("~/.ssh/id_ed25519.pub") # Public key file path
  tags       = { Name = "DeployerKey" }      # Tag for identification
}

# -----------------------
# VPC & Subnets
# -----------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"        # VPC CIDR range
  enable_dns_support   = true                 # Enables DNS resolution
  enable_dns_hostnames = true                 # Enables DNS hostnames
  tags                 = { Name = "MainVPC" } # VPC name tag
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id           # Attach subnet to VPC
  cidr_block              = "10.0.1.0/24"             # Public subnet CIDR
  map_public_ip_on_launch = true                      # Auto-assign public IPs
  availability_zone       = "us-east-1a"              # AZ for subnet
  tags                    = { Name = "PublicSubnet" } # Tag
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id             # Attach to VPC
  cidr_block        = "10.0.10.0/24"              # Private subnet CIDR
  availability_zone = "us-east-1a"                # AZ
  tags              = { Name = "PrivateSubnet1" } # Tag
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id             # Attach to VPC
  cidr_block        = "10.0.11.0/24"              # Another private subnet
  availability_zone = "us-east-1b"                # Different AZ
  tags              = { Name = "PrivateSubnet2" } # Tag
}

# -----------------------
# Internet Gateway & Route Table
# -----------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id              # Attach to VPC
  tags   = { Name = "InternetGateway" } # Tag
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id # Route table for VPC
  route {
    cidr_block = "0.0.0.0/0"                # Route to all IPs
    gateway_id = aws_internet_gateway.gw.id # Internet access
  }
  tags = { Name = "PublicRouteTable" } # Tag
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id      # Link public subnet
  route_table_id = aws_route_table.public.id # With public route table
}

# -----------------------
# Security Groups
# -----------------------
resource "aws_security_group" "ec2_sg" {
  name   = "ec2-sg"        # Security group name
  vpc_id = aws_vpc.main.id # Attach to VPC

  ingress {
    from_port   = 22 # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world
  }

  ingress {
    from_port   = 443 # HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Internal only
  }

  egress {
    from_port   = 0 # All traffic allowed
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "EC2SecurityGroup" } # Tag
}

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306 # MySQL
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Internal access only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "RDSSecurityGroup" } # Tag
}

# -----------------------
# RDS Subnet Group
# -----------------------
resource "aws_db_subnet_group" "default" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id] # Private subnets
  tags       = { Name = "RDSSubnetGroup" }                      # Tag
}

# -----------------------
# RDS MySQL Instance
# -----------------------
resource "aws_db_instance" "mysql" {
  identifier             = "my-rds"
  allocated_storage      = 20      # 20 GB storage
  engine                 = "mysql" # Engine
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" # Small instance
  db_name                = "mydb"
  username               = "admin"
  password               = "Admin1234!"
  db_subnet_group_name   = aws_db_subnet_group.default.name # Attach subnet group
  vpc_security_group_ids = [aws_security_group.rds_sg.id]   # Use RDS SG
  skip_final_snapshot    = true                             # No snapshot on destroy
  publicly_accessible    = false                            # Internal only
  apply_immediately      = true                             # Immediate apply
  tags                   = { Name = "MySQLInstance" }       # Tag
}

# -----------------------
# Secrets Manager
# -----------------------
resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = "RDS-Credentials" # Secret name
  description             = "RDS MySQL Credentials"
  recovery_window_in_days = 0                      # Delete immediately
  tags                    = { Name = "RDSSecret" } # Tag
}

resource "aws_secretsmanager_secret_version" "initial_secret" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({ # Store DB credentials
    username = aws_db_instance.mysql.username,
    password = aws_db_instance.mysql.password,
    host     = aws_db_instance.mysql.address,
    dbname   = aws_db_instance.mysql.db_name
  })
  depends_on = [aws_db_instance.mysql]
}

# -----------------------
# VPC Endpoint for Secrets Manager
# -----------------------
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private1.id, aws_subnet.private2.id]
  security_group_ids  = [aws_security_group.ec2_sg.id]
  private_dns_enabled = true
  tags                = { Name = "SecretsManagerVPCEndpoint" }
}

# -----------------------
# IAM Role & Instance Profile for EC2
# -----------------------
resource "aws_iam_role" "ec2_secrets_role" {
  name = "EC2SecretsAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "allow_secrets" {
  name = "SecretsManagerAccess"
  role = aws_iam_role.ec2_secrets_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = aws_secretsmanager_secret.rds_secret.arn
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_secrets_role.name
}

# -----------------------
# EC2 Bastion Instance
# -----------------------
resource "aws_instance" "bastion" {
  ami                         = "ami-02457590d33d576c3" # Amazon Linux 3 AMI
  instance_type               = "t2.micro"              # Small EC2
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true # Public access
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = file("install.sh") # Run bootstrap script

  tags = { Name = "BastionHost" }

  # Ensure the secret version and VPC endpoint exist before we launch the EC2
  depends_on = [
    aws_secretsmanager_secret_version.initial_secret, # Wait for secret
    aws_vpc_endpoint.secretsmanager                   # Wait for VPC endpoint
  ]

  # Upload init.sql to EC2 instance
  provisioner "file" {
    source      = "init.sql"
    destination = "/tmp/init.sql"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.public_ip
    }
  }

  # Remote execution on EC2 to install tools and initialize DB
  provisioner "remote-exec" {
    inline = [

      # 1. Install MariaDB client + jq
      "sudo yum install -y mariadb105-server jq", # Install tools
      "mysql --version",


      # 2. Get credentials from AWS Secrets Manager
      "aws secretsmanager get-secret-value --secret-id RDS-Credentials --query SecretString --output text > /tmp/creds.json", # Get secret

      "export DB_HOST=$(jq -r .host /tmp/creds.json)", # Parse credentials
      "export DB_USER=$(jq -r .username /tmp/creds.json)",
      "export DB_PASS=$(jq -r .password /tmp/creds.json)",
      "export DB_NAME=$(jq -r .dbname /tmp/creds.json)",

      # 4. Run init.sql
      "mysql -h \"$DB_HOST\" -u \"$DB_USER\" -p\"$DB_PASS\" \"$DB_NAME\" < /tmp/init.sql", # Run init.sql



      # 5. Create /tmp/mysql.sh script for future access
      "cat << 'EOF' > /tmp/mysql.sh", # Save script for reuse
      "#!/bin/bash",
      "export DB_HOST=$(jq -r .host /tmp/creds.json)",
      "export DB_USER=$(jq -r .username /tmp/creds.json)",
      "export DB_PASS=$(jq -r .password /tmp/creds.json)",
      "export DB_NAME=$(jq -r .dbname /tmp/creds.json)",
      "mysql -h \"$DB_HOST\" -u \"$DB_USER\" -p\"$DB_PASS\" \"$DB_NAME\"",
      "EOF",

      # 6. Make script executable
      "chmod +x /tmp/mysql.sh" # Make script executable
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.public_ip
    }
  }
}
