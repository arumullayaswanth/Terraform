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
**NOTES**
## What is state and why is it important in Terraform? #########
“Terraform must store state about your managed infrastructure and configuration. This state is used by Terraform to map real world resources to your configuration, keep track of metadata, and to improve performance for large infrastructures. This state file is extremely important; it maps various resource metadata to actual resource IDs so that Terraform knows what it is managing. This file must be saved and distributed to anyone who might run Terraform.”

Remote State:
“By default, Terraform stores state locally in a file named terraform.tfstate. When working with Terraform in a team, use of a local file makes Terraform usage complicated because each user must make sure they always have the latest state data before running Terraform and make sure that nobody else runs Terraform at the same time.”

“With remote state, Terraform writes the state data to a remote data store, which can then be shared between all members of a team.”

State Lock:
“If supported by your backend, Terraform will lock your state for all operations that could write state. This prevents others from acquiring the lock and potentially corrupting your state.”

“State locking happens automatically on all operations that could write state. You won’t see any message that it is happening. If state locking fails, Terraform will not continue. You can disable state locking for most commands with the -lock flag but it is not recommended.”

## Setting up our S3 Backend 
Create a new file in your working directory labeled Backend.tf
Copy and paste this configuration in your source code editor in your backend.tf file.

## Creating our DynamoDB Table 

 Create a new file in your working directory labeled dynamo.tf
 
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
Temporarily Comment Out the Backend Block
the backend is defined, comment out this block for now:
***
.# terraform {

.#   backend "s3" {

.#     bucket         = "terraform-state-lock-yaswanth6758546"

.#     key            = "terraform.tfstate"

.#     region         = "us-east-1"

.#     dynamodb_table = "terraform-state-lock-dynamo"

.#     encrypt        = true

.#   }

.# }****


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
   
.# terraform {

.#   backend "s3" {

.#     bucket         = "terraform-state-lock-yaswanth6758546"

.#     key            = "terraform.tfstate"

.#     region         = "us-east-1"

.#     dynamodb_table = "terraform-state-lock-dynamo"

.#     encrypt        = true

.#   }

.# }

5. Re-initialize backend:

   ```bash
   terraform init
   ```

   Confirm when prompted to migrate local state → type `yes`

6. Apply full project:

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





# Terraform Project: EC2 + S3 (Remote State Only in S3)

## Overview

This guide walks you through building a Terraform project that:

* Deploys an EC2 instance and S3 bucket
* Stores Terraform state remotely in S3 (without DynamoDB locking)
* Supports multi-developer collaboration (manual coordination)

## ✅ Project Breakdown

You will:

1. Set up the S3 backend bucket
2. Configure Terraform to use remote backend (only S3)
3. Deploy EC2 and S3 resources

## 🛠 Prerequisites

* ✅ AWS CLI installed and configured (`aws configure`)
* ✅ Terraform installed (`terraform -v`)
* ✅ AWS key pair created in `us-east-1` (e.g., `ec2test`)
* ✅ IAM user with EC2 and S3 permissions

---

## 📁 Directory Structure

```
terraform-ec2-s3-remote-state-s3-only/
├── provider.tf
├── variables.tf
├── state-resources.tf
├── state-backend.tf
├── main.tf
├── outputs.tf
├── README.md
```

---

## 🔹 Step 1: `provider.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

---

## 🔹 Step 2: `variables.tf`

```hcl
variable "ami" {
  default = "ami-085ad6ae776d8f09c"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "ec2test"
}

variable "ec2_name_tag" {
  default = "dev"
}

variable "ec2_az" {
  default = "us-east-1a"
}

variable "bucket_name" {
  default = "multicloudnareshitveera"
}

variable "state_bucket" {
  default = "veeranareshitdevopsss"
}
```

---

## 🔹 Step 3: `state-resources.tf`

```hcl
resource "aws_s3_bucket" "tf_backend" {
  bucket = var.state_bucket

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
```

---

## 🔹 Step 4: `state-backend.tf`

```hcl
# terraform {
#   backend "s3" {
#     bucket  = "veeranareshitdevopsss"
#     key     = "terraform.tfstate"
#     region  = "us-east-1"
#     encrypt = true
#   }
# }

#or

terraform {
  backend "s3" {
    bucket  = "veeranareshitdevopsss"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}


```

> ⚠️ Apply backend bucket before enabling this block.

---

## 🔹 Step 5: `main.tf`

```hcl
resource "aws_instance" "example" {
  ami               = var.ami
  instance_type     = var.instance_type
  key_name          = var.key_name
  availability_zone = var.ec2_az

  tags = {
    Name = var.ec2_name_tag
  }
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = var.bucket_name
}
```

---

## 🔹 Step 6: `outputs.tf`

```hcl
output "ec2_instance_id" {
  value = aws_instance.example.id
}

output "bucket_name" {
  value = aws_s3_bucket.code_bucket.bucket
}
```

---

## 🔹 Step 7: Step-by-Step Commands

```bash
# Step 1: Go to your project directory
cd terraform-ec2-s3-remote-state-s3-only

# Step 2: Initialize Terraform
terraform init

# Step 3: Create only the S3 backend bucket
terraform apply -target=aws_s3_bucket.tf_backend

# Step 4: Enable remote backend by uncommenting backend block in state-backend.tf
# Then re-initialize Terraform to switch to remote backend
terraform init

# Step 5: Confirm backend migration when prompted
# Type "yes" to migrate state

# Step 6: Apply your infrastructure
terraform apply
```

---

## ⚠️ Multi-Developer Notes (No Locking)

* No DynamoDB state locking = no automatic protection
* Use manual coordination (e.g., Slack, PR reviews) to avoid race conditions
* Always pull the latest `.tf` changes before applying

---

## ✅ Summary

* ✅ EC2 instance and general-purpose S3 bucket deployed
* ✅ Terraform remote state stored in S3 only
* ⚠️ Manual coordination required for multi-developer workflows (no locking)

