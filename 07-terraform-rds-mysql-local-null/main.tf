# Configure AWS provider and specify region
provider "aws" {
  region = "us-east-1"  # AWS region where resources will be created
}

# Create a DB subnet group for RDS spanning two subnets
resource "aws_db_subnet_group" "default" {
  name       = "default-subnet-group"  # Name of subnet group
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]  # Associate subnets

  tags = {
    Name = "Default subnet group"  # Tag for identification
  }
}

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"  # CIDR block for the VPC
}

# Create the first subnet in availability zone us-east-1a
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc.id  # Attach subnet to VPC
  cidr_block        = "10.0.1.0/24"   # Subnet CIDR block
  availability_zone = "us-east-1a"    # AZ for subnet
}

# Create the second subnet in availability zone us-east-1b
resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.vpc.id  # Attach subnet to VPC
  cidr_block        = "10.0.2.0/24"   # Subnet CIDR block
  availability_zone = "us-east-1b"    # AZ for subnet
}

# Create a Security Group for the RDS allowing inbound MySQL traffic
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"    # Security group name
  description = "Allow MySQL inbound"   # Description of purpose
  vpc_id      = aws_vpc.vpc.id           # Attach to VPC

  ingress {
    from_port   = 3306                   # MySQL port start
    to_port     = 3306                   # MySQL port end
    protocol    = "tcp"                  # TCP protocol
    cidr_blocks = ["0.0.0.0/0"]          # Allow all inbound (demo only; restrict in prod)
  }

  egress {
    from_port   = 0                     # Allow all outbound traffic
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Provision the AWS RDS MySQL instance
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20                      # Storage in GB
  engine               = "mysql"                 # Database engine type
  engine_version       = "8.0"                   # MySQL version
  instance_class       = "db.t3.micro"           # Instance type
  name                 = "mydb"                   # Initial DB name
  username             = "admin"                  # Master username
  password             = "Admin1234!"             # Master password (change this!)
  db_subnet_group_name = aws_db_subnet_group.default.name  # Subnet group for RDS
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  # Attach security group
  skip_final_snapshot  = true                     # Skip snapshot on destroy
  publicly_accessible  = true                     # Accessible over public internet (dev only)
  multi_az             = false                    # Single AZ deployment
}

# Null resource to run local-exec provisioner for DB initialization
resource "null_resource" "init_db" {
  depends_on = [aws_db_instance.mysql]  # Ensure RDS is created before this runs

  provisioner "local-exec" {
    # Use bash commands to wait for RDS to be reachable and then execute SQL script
    command = <<EOT
      # Loop to check if MySQL port is open on RDS instance
      for i in {1..30}; do
        nc -zvw3 ${aws_db_instance.mysql.address} 3306 && break
        echo "Waiting for MySQL to be available..."
        sleep 10
      done

      # Execute the SQL script to setup database schema and data
      mysql -h ${aws_db_instance.mysql.address} -P 3306 -u admin -pAdmin1234! mydb < init.sql
    EOT
    interpreter = ["/bin/bash", "-c"]  # Run commands using bash shell
  }
}
