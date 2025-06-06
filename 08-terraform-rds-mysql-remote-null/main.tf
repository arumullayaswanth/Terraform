
provider "aws" {
  region = "us-east-1"
}

# — Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# — VPC & Subnets
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "MainVPC" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags                    = { Name = "PublicSubnet" }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "PrivateSubnet1" }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "PrivateSubnet2" }
}

# — Internet Gateway & Route
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "InternetGateway" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "PublicRouteTable" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# — Security Groups
resource "aws_security_group" "ec2_sg" {
  name   = "ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "EC2SecurityGroup" }
}

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "RDSSecurityGroup" }
}

# — DB Subnet Group
resource "aws_db_subnet_group" "default" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
  tags       = { Name = "RDSSubnetGroup" }
}

# — RDS MySQL
resource "aws_db_instance" "mysql" {
  identifier             = "my-rds"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "mydb"
  username               = "admin"
  password               = "Admin1234!"
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  apply_immediately      = true
  tags                   = { Name = "MySQLInstance" }
}

# — Secrets Manager Secret & Version
resource "aws_secretsmanager_secret" "rds_secret" {
  name        = "rds-credentials-new-2"
  description = "RDS MySQL Credentials"
}

resource "aws_secretsmanager_secret_version" "initial_secret" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = aws_db_instance.mysql.username
    password = aws_db_instance.mysql.password
    host     = aws_db_instance.mysql.address
    dbname   = aws_db_instance.mysql.db_name
  })
  depends_on = [aws_db_instance.mysql]
}

# — VPC Endpoint for Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private1.id, aws_subnet.private2.id]
  security_group_ids  = [aws_security_group.ec2_sg.id]
  private_dns_enabled = true
  tags                = { Name = "SecretsManagerVPCEndpoint" }
}

# — IAM Role and Instance Profile for EC2
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
      Effect = "Allow",
      Action = [
        "secretsmanager:GetSecretValue"
      ],
      Resource = aws_secretsmanager_secret.rds_secret.arn
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_secrets_role.name
}

# — EC2 Bastion with init.sql executor
resource "aws_instance" "bastion" {
  ami                         = "ami-02457590d33d576c3"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = file("install.sh")

  tags = { Name = "BastionHost" }

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

  provisioner "remote-exec" {
    inline = [
      "sudo dnf clean all",
      "sudo rm -f /etc/yum.repos.d/mysql-community.repo",
      "sudo rm -f /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022",
      "sudo dnf install -y --nogpgcheck https://repo.mysql.com/mysql80-community-release-el9-1.noarch.rpm",
      "sudo dnf install -y --nogpgcheck mysql-community-client jq",
      "mysql --version",
       "aws secretsmanager get-secret-value --secret-id rds-credentials-new-2 --query SecretString --output text > /tmp/creds.json",
        "DB_HOST=$(jq -r .host /tmp/creds.json)",
      "DB_USER=$(jq -r .username /tmp/creds.json)",
      "DB_PASS=$(jq -r .password /tmp/creds.json)",
      "DB_NAME=$(jq -r .dbname /tmp/creds.json)",

       "mysql -h \"$DB_HOST\" -u \"$DB_USER\" -p\"$DB_PASS\" \"$DB_NAME\" < /tmp/init.sql"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.public_ip
    }
  }
}
