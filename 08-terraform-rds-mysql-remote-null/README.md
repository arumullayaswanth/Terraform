# Terraform Project: AWS RDS MySQL with Remote Null Resource Execution

## Overview

This project provisions:

* A secure VPC with two subnets and an internet gateway
* A MySQL RDS instance in a private subnet
* An EC2 instance in a public subnet to act as a remote executor
* A null resource with `remote-exec` provisioner
* A MySQL client installed on the EC2 instance
* An SQL script (`init.sql`) executed remotely to initialize RDS

---

## Folder Structure

```
terraform-rds-mysql-remote-null/
├── main.tf
├── init.sql
├── README.md
```

---

## Prerequisites

* Terraform installed
* AWS CLI configured
* Key pair file for SSH (e.g., `my-key.pem`)

---

## Step-by-Step Implementation

### Step 1: Write `main.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  vpc_id      = aws_vpc.main.id

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
}

resource "aws_db_subnet_group" "default" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private.id]

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-0c2b8ca1dad447f8a"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.deployer.key_name

  tags = {
    Name = "BastionHost"
  }

  provisioner "file" {
    source      = "init.sql"
    destination = "/home/ec2-user/init.sql"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y mysql",
      "while ! mysql -h ${aws_db_instance.mysql.address} -u admin -pAdmin1234! -e 'SELECT 1;' mydb; do echo 'Waiting for DB...'; sleep 10; done",
      "mysql -h ${aws_db_instance.mysql.address} -u admin -pAdmin1234! mydb < /home/ec2-user/init.sql"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "Admin1234!"
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
}
```

---

### Step 2: Write `init.sql`

```sql
-- Create table
CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50),
  price DECIMAL(10,2)
);

-- Insert data
INSERT INTO products (name, price) VALUES ('Laptop', 999.99), ('Mouse', 19.99), ('Keyboard', 49.99);
```

---

### Step 3: Terraform Commands

```bash
terraform init
terraform plan
terraform apply
```

Confirm with `yes`.

---

### Step 4: Verify RDS Setup

SSH into EC2:

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<EC2_PUBLIC_IP>
```

Connect to DB manually:

```bash
mysql -h <RDS_ENDPOINT> -u admin -p mydb
```

Check data:

```sql
SELECT * FROM products;
```

---

### Step 5: Destroy Infrastructure

```bash
terraform destroy
```

---

## Notes

* Replace AMI ID and region according to your AWS setup.
* Make sure your SSH key is accessible and permissions are correct (`chmod 400 ~/.ssh/id_rsa`).
* Only allow public access to EC2 for provisioning purposes.
* You can automate access further by using user data or SSM.

---

**End of Guide**
