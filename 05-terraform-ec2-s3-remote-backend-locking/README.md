# Terraform Project: EC2 + S3 + Remote State with Locking

## Overview

This guide walks you through building a Terraform project that:

* Deploys an EC2 instance and S3 bucket
* Uses remote state stored in S3
* Enables state locking with DynamoDB

## ✅ Overview of the Full Project

You will:

1. Set up Terraform backend (state bucket + DynamoDB)
2. Configure Terraform to use remote backend with locking
3. Deploy an EC2 instance and an S3 bucket (your main resources)

## 🛠 Prerequisites

Before you begin:

* ✅ AWS CLI is installed and configured (`aws configure`)
* ✅ Terraform is installed (`terraform -v`)
* ✅ An AWS Key Pair exists in `us-east-1` (e.g., `ec2test`)
* ✅ IAM user has access to create S3, EC2, and DynamoDB resources

---

## 📁 Directory Structure

```
terraform-ec2-s3-remote-backend-locking/
├── provider.tf                # AWS provider and Terraform version setup
├── variables.tf               # All input variables
├── main.tf                    # EC2 and S3 resource definitions
├── state-resources.tf         # Resources for backend (S3 + DynamoDB)
├── state-backend.tf           # Backend configuration (S3 + DynamoDB lock)
├── outputs.tf                 # Output values
├── README.md                  # The markdown file with step-by-step guide

```

---

## 🔹 Step 1: `provider.tf`

```hcl
# Declare the required Terraform provider and its version
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Source of the AWS provider
      version = ">= 4.0"         # Minimum required version
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "us-east-1"  # Region where resources will be created
}

```

---

## 🔹 Step 2: `variables.tf`

```hcl
# Define input variables and their default values

variable "ami" {
  default = "ami-085ad6ae776d8f09c"  # Amazon Machine Image ID
}

variable "instance_type" {
  default = "t2.micro"  # Free tier eligible instance type
}

variable "key_name" {
  default = "ec2test"  # Existing key pair name for SSH
}

variable "ec2_name_tag" {
  default = "dev"  # Tag name for EC2 instance
}

variable "ec2_az" {
  default = "us-east-1a"  # Availability zone for EC2
}

variable "bucket_name" {
  default = "multicloudnareshitveera"  # S3 bucket for general use
}

variable "state_bucket" {
  default = "veeranareshitdevopsss"  # S3 bucket for storing Terraform state
}

variable "dynamodb_table" {
  default = "terraform-state-lock-dynamo"  # DynamoDB table name for state locking
}

```

---

### 🔹 Step 3: `state-resources.tf`

> 🔸 This creates the **S3 bucket and DynamoDB table** for state storage and locking.

```hcl
# Create S3 bucket to store Terraform remote state
resource "aws_s3_bucket" "tf_backend" {
  bucket = var.state_bucket  # Use variable for bucket name

  # Enable versioning for state file history
  versioning {
    enabled = true
  }

  # Enable default server-side encryption (AES256)
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create DynamoDB table for state file locking
resource "aws_dynamodb_table" "tf_lock" {
  name         = var.dynamodb_table   # Table name from variable
  billing_mode = "PAY_PER_REQUEST"   # No need to specify read/write capacity
  hash_key     = "LockID"            # Partition key

  # Define key schema
  attribute {
    name = "LockID"
    type = "S"  # String type
  }
}

```

---

### Step 5: `state-backend.tf`

Now that the backend exists, configure it:

```hcl
# Configure remote backend to use S3 and DynamoDB
terraform {
  backend "s3" {
    bucket         = "veeranareshitdevopsss"          # S3 bucket name
    key            = "terraform.tfstate"              # Path to state file in bucket
    region         = "us-east-1"                      # Bucket region
    dynamodb_table = "terraform-state-lock-dynamo"    # DynamoDB table for locking
    encrypt        = true                             # Encrypt the state file at rest
  }
}

```

⚠️ This block should be used **after** the backend bucket and table are created (`terraform apply -target=...`).

---

### 🔹 Step 7: `main.tf`

> This contains your actual infrastructure: EC2 instance and app S3 bucket.

```hcl
# Create an EC2 instance
resource "aws_instance" "example" {
  ami               = var.ami           # Use the provided AMI ID
  instance_type     = var.instance_type # Instance type (t2.micro)
  key_name          = var.key_name      # Key pair for SSH access
  availability_zone = var.ec2_az        # AZ in which to launch

  # Add a Name tag
  tags = {
    Name = var.ec2_name_tag
  }
}

# Create a general-purpose S3 bucket
resource "aws_s3_bucket" "code_bucket" {
  bucket = var.bucket_name  # Name from variable
}

```

---

## 🔹 Step 8: `outputs.tf` (Optional)

```hcl
# Output the EC2 instance ID
output "ec2_instance_id" {
  value = aws_instance.example.id
}

# Output the name of the created S3 bucket
output "bucket_name" {
  value = aws_s3_bucket.code_bucket.bucket
}

```

---

## Deployment Steps

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Apply backend resources:

   ```bash
   terraform apply -target=aws_s3_bucket.tf_backend -target=aws_dynamodb_table.tf_lock
   ```

3. Uncomment backend block in `state-backend.tf` if not already done

4. Re-initialize backend:

   ```bash
   terraform init
   ```

   Confirm when prompted to migrate local state → type `yes`

5. Apply full project:

   ```bash
   terraform apply
   ```

---

## Done!

You now have:

* An EC2 instance
* A general S3 bucket
* Remote state stored in S3
* Locking managed by DynamoDB
