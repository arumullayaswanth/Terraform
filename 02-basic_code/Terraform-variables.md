# Terraform Variable Files

Terraform **variable files** (`.tfvars`) allow you to store variables separately, making configurations more modular and reusable.

---

## 📌 Why Use Terraform Variable Files?

- Separates configuration logic from variable values.
- Enables different environments (e.g., dev, test, prod) with different settings.
- Improves maintainability and flexibility in infrastructure automation.

---

## 📂 Creating a Terraform Project

```bash
mkdir terraform
cd terraform
```

---

## Example 1️⃣: Basic EC2 Instance Deployment with Variables

### 1️⃣ `main.tf` (Terraform Configuration)

```hcl
provider "aws" {
  region = "us-east-1"  # AWS Region (Mumbai)
}

resource "aws_instance" "one" {
  count = var.instance_count  # Number of instances to create
  ami = "ami-03eb6185d756497f8"  # Amazon Linux 2 AMI (ap-south-1)
  instance_type = var.instance_type  # Instance type (customizable)

  tags = {
    Name = "TerraformInstance-${count.index + 1}"  # Unique name for each instance
  }
}

variable "instance_type" {
  description = "Instance type to be used (e.g., t2.micro, t3.medium)"
  type = string
  default = "t2.micro"  # Default value
}

variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type = number
  default = 5  # Default value
}
```

### ✅ Running Terraform Commands

```bash
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy -auto-approve
```

---

## Example 2️⃣: Multiple EC2 Instances with Variable Files

### 1️⃣ `main.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "one" {
  count         = var.instance_count
  ami           = "ami-02f624c08a83ca16f"
  instance_type = var.instance_type

  tags = {
    Name = "yaswanth-server-${count.index + 1}"
  }
}

```

### 2️⃣ `variables.tf`

```hcl
variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 3  # Change as needed
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro"  # Change as needed
}
```

### ✅ Running Terraform Commands

```bash
terraform init       # Initialize Terraform
terraform plan       # Preview changes
terraform apply -auto-approve  # Deploy EC2 instances
terraform state list
terraform destroy -auto-approve
terraform destroy -auto-approve -target="aws_instance.one[1]"
```

---

## Example 3️⃣: Using Different Environments (Development & Testing)

### 1️⃣ `main.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "one" {
  count         = var.instance_count
  ami           = "ami-02f624c08a83ca16f"
  instance_type = var.instance_type

  tags = {
    Name = "yaswanth-server-${count.index + 1}"
  }
}
```

### 2️⃣ `variables.tf`

```hcl
variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
```

### 3️⃣ `dev.tfvars` (Development Environment)

```hcl
instance_count = 1
instance_type  = "t2.micro"
```

### 4️⃣ `test.tfvars` (Testing Environment)

```hcl
instance_count = 2
instance_type  = "t2.medium"
```

### ✅ Running Terraform with Different Environments
### ✅ Running Terraform Commands

```bash
# Run Terraform with the development environment
terraform apply -var-file="dev.tfvars" -auto-approve

# Run Terraform with the testing environment
terraform apply -var-file="test.tfvars" -auto-approve

# Destroy resources for a specific environment
terraform destroy -var-file="dev.tfvars" -auto-approve
```

### ✅ Solutions to Ensure New Instances are Created Instead of Modifying Existing Ones
### 1️⃣ Use Separate State Files for Each Environment
By default, Terraform uses a single state file (terraform.tfstate). To avoid modifying the same resources, you can use different backend state files:

```bash
# Development environment
terraform apply -var-file="dev.tfvars" -auto-approve -state="dev.tfstate"

# Testing environment
terraform apply -var-file="test.tfvars" -auto-approve -state="test.tfstate"


```

✅ **Using variable files makes Terraform configurations more modular and environment-specific!**

