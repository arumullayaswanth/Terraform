# Terraform Project: EC2 Deployment with Full Networking and Provisioning

## Overview

This guide provides a step-by-step Terraform implementation to provision:

* A custom VPC with subnet and internet access
* A security group with SSH and HTTP access
* An EC2 instance
* File uploads and remote command execution using provisioners

---

## Folder Structure

```
terraform-ec2-full-setup/
├── main.tf
├── file10                   # Sample file to upload to EC2
```

---

## Step-by-Step Instructions

### Step 1: Define Infrastructure in `main.tf`

```hcl
# Define the AWS provider configuration.
provider "aws" {
  region = "us-east-1"
}

# Create key pair from your local public key
resource "aws_key_pair" "example" {
  key_name   = "public-key"
  public_key = file("C:/Users/Yaswanth Reddy/.ssh/id_ed25519.pub")

  tags = {
    Name = "Public-Key"
  }
}

# VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "My-VPC"
  }
}


# Subnet
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}


# Route Table
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Route-Table"
  }
}


# Associate Route Table with Subnet
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

# Security Group
resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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

  tags = {
    Name = "Web-SG"
  }
}

# EC2 Instance
resource "aws_instance" "server" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id

  tags = {
    Name = "EC2-Ubuntu"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("C:/Users/Yaswanth Reddy/.ssh/id_ed25519")
    host        = self.public_ip
  }

 # Local command
  provisioner "local-exec" {
    command = "touch file500"
  }
# File copy
  provisioner "file" {
    source      = "file10"
    destination = "/home/ubuntu/file10"
  }

# Remote command
  provisioner "remote-exec" {
    inline = [
      "touch file200",
      "echo hello from aws >> file200",
    ]
  }
}


```

---

### Step 2: Create Sample File for Upload

```bash
echo "This is file10" > file10
```

---

### Step 3: Initialize Terraform

```bash
terraform init
```

---

### Step 4: Validate the Configuration

```bash
terraform validate
```

---

### Step 5: Plan the Infrastructure

```bash
terraform plan
```

---

### Step 6: Apply the Changes

```bash
terraform apply
```

Type `yes` to confirm the creation.

---

### Step 7: Verify in AWS Console

* EC2 > Instances → Confirm instance is running
* VPC > Subnets, IGW, Route Table → Confirm network setup
* Security Groups → Confirm SSH and HTTP rules

### Step 8: Connect to EC2 and Verify File

After the instance is up and running, connect to it via SSH to confirm the file has been uploaded and the remote commands executed.

#### SSH into the EC2 instance

```
ssh -i ~/.ssh/id_rsa ubuntu@<PUBLIC_IP>
```

> Replace `<PUBLIC_IP>` with the actual public IP address of the EC2 instance (you can find it in the Terraform output or AWS console).

#### Verify uploaded file

```
ls -l /home/ubuntu/file10 
cat /home/ubuntu/file10
```

CopyEdit

`ls -l /home/ubuntu/file10 cat /home/ubuntu/file10`

You should see:

```
This is file10
```

#### Verify remote-exec created file

```
cat file200
```

You should see:

```
hello from aws
```

---

### Step 8: Cleanup (Optional)

```bash
terraform destroy
```

---

## Notes

* Ensure `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` exist.
* Adjust file paths if you're using Windows.
* For Amazon Linux AMIs, use `ec2-user` instead of `ubuntu`.

---

You're now ready to deploy a full AWS EC2 infrastructure with Terraform!



## Terraform Output File for EC2 Provisioning

### 📌 Project Summary

This Terraform configuration provisions the following AWS resources:

* One VPC and public subnet
* Internet Gateway and Route Table for public access
* Security Group allowing HTTP (80) and SSH (22)
* Key Pair for SSH access
* EC2 instance with file and command provisioners

---

### ✅ Outputs

```hcl
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.server.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.server.public_dns
}

output "ec2_id" {
  description = "Instance ID of the EC2 instance"
  value       = aws_instance.server.id
}
```

---

### 🛠 How to Use

1. Add the above output block to a file named `outputs.tf`
2. Run:

```bash
terraform apply
```

3. After deployment, Terraform will display:

```
ec2_public_ip = "<IP_ADDRESS>"
ec2_public_dns = "<DNS_NAME>"
ec2_id = "<INSTANCE_ID>"
```

Use the public IP/DNS to connect to the instance or verify access.

---

Let me know if you want this merged into your main `.tf` file or included in your GitHub `README.md`. ✅

