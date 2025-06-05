# Configure the AWS provider and region
provider "aws" {
  region = "us-east-1"  # AWS region where resources will be created
}

# Create a VPC with DNS support and hostnames enabled
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"      # Network range for the VPC
  enable_dns_support   = true              # Enables DNS resolution
  enable_dns_hostnames = true              # Enables DNS hostnames

  tags = {
    Name = "MyVPC"                         # Tag for identification
  }
}

# Create a public subnet in availability zone us-east-1a
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc.id           # Associate with created VPC
  cidr_block              = "10.0.1.0/24"            # Subnet CIDR range
  availability_zone       = "us-east-1a"             # AZ for redundancy
  map_public_ip_on_launch = true                     # Automatically assign public IP

  tags = {
    Name = "Public Subnet 1"
  }
}

# Create a second public subnet in a different availability zone
resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 2"
  }
}

# Internet Gateway to allow access to/from the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Main IGW"
  }
}

# Route table with default route to internet gateway
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"                 # Route all outbound traffic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public RT"
  }
}

# Associate subnet1 with the route table
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}

# Associate subnet2 with the same route table
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt.id
}

# Define a DB Subnet Group for RDS using both subnets
resource "aws_db_subnet_group" "default" {
  name       = "default-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "Default subnet group"
  }
}

# Security group to allow MySQL access
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow MySQL inbound"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3306                     # MySQL default port
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]           # Allow from anywhere (Not recommended for prod)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"                    # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS SG"
  }
}

# RDS MySQL instance
resource "aws_db_instance" "mysql" {
  allocated_storage       = 20                         # Disk size in GB
  engine                  = "mysql"                    # DB engine
  engine_version          = "8.0"                      # Version of MySQL
  instance_class          = "db.t3.micro"              # Instance type
  db_name                 = "mydb"                     # Initial database
  username                = "admin"                    # DB master username
  password                = "Admin1234!"               # DB password (should use sensitive variables)
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = true                       # Allow public access (Not recommended for prod)
  multi_az                = false                      # Single AZ deployment
  skip_final_snapshot     = true                       # Skip snapshot on deletion

  tags = {
    Name = "mysql-db"
  }
}

# Initialize the MySQL database using a local script
resource "null_resource" "init_db" {
  depends_on = [aws_db_instance.mysql]  # Wait for DB to be ready

  provisioner "local-exec" {
    interpreter = ["C:\\Program Files\\Git\\bin\\bash.exe", "-c"]  # Run the command with Git Bash on Windows
    command = <<EOT
      # Wait for MySQL to accept connections
      for i in {1..30}; do
        timeout 1 bash -c "</dev/tcp/${aws_db_instance.mysql.address}/3306" && break
        echo "Waiting for MySQL to be available..."
        sleep 10
      done

      # Initialize DB using init.sql
      "/c/Program Files/MySQL/MySQL Server 8.0/bin/mysql" -h ${aws_db_instance.mysql.address} -P 3306 -u admin -pAdmin1234! mydb < init.sql
    EOT
  }
}
