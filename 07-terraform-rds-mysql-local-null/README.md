# 🚀 Terraform Project: RDS MySQL with local  Null Resource Initialization

## 📘 Overview

This project provisions an AWS RDS MySQL database inside a VPC using Terraform. It includes:

- VPC and Subnets creation
- RDS DB Subnet Group
- Security Group with MySQL access
- MySQL RDS instance
- A `null_resource` to run an `init.sql` file using a `local-exec` provisioner after the database is ready

---

## 📁 Folder Structure

```
terraform-rds-mysql-null/
├── main.tf         # Terraform config with infra and provisioner
├── init.sql        # SQL script to initialize the database
└── README.md       # Project documentation
```

---

## 🛠️ Prerequisites

- ✅ AWS CLI configured (`aws configure`)
- ✅ Terraform ≥ 1.0 installed (`terraform --version`)
- ✅ MySQL client installed (`mysql --version`)
- ✅ `nc` (netcat) installed (used to check port availability)

---

## ⚙️ Terraform Setup

### Step 1: Clone the Project

```bash
git clone https://github.com/your-repo/terraform-rds-mysql-null.git
cd terraform-rds-mysql-null
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Validate the Configuration

```bash
terraform validate
```

### Step 4: Preview the Execution Plan

```bash
terraform plan
```

### Step 5: Apply the Terraform Plan

```bash
terraform apply
```

✅ When prompted, type `yes` to confirm.

Terraform will:
- Provision VPC, subnets, security groups
- Launch an RDS MySQL instance
- Wait for the DB to be reachable
- Run the `init.sql` using MySQL CLI from your local machine

---

## 🔗 Connecting to the RDS MySQL Instance

Get the endpoint from the Terraform output or AWS Console and connect:

```bash
mysql -h <RDS_ENDPOINT> -u admin -p mydb
```

Password: `Admin1234!`

---

## 📊 Verifying the Data

Once connected, you can run:

```sql
SHOW TABLES;
SELECT * FROM departments;
SELECT * FROM employees;
SELECT * FROM projects;
SELECT * FROM assignments;
```

---

## 🧹 Clean-Up Resources

To remove all infrastructure:

```bash
terraform destroy
```

Confirm with `yes`.

---

## ⚠️ Notes & Warnings

- The security group opens port 3306 to the world (`0.0.0.0/0`) — **ONLY FOR DEMO**. Restrict it in production.
- The password is hardcoded. For production, use `terraform.tfvars` or integrate with AWS Secrets Manager.
- Your machine must have MySQL and netcat (`nc`) installed to execute the SQL script.
- Modify CIDRs, AZs, or instance size as needed.

---

## ✅ Summary

You're now set up to:
- Provision a complete RDS MySQL infrastructure with Terraform
- Initialize your DB automatically with `init.sql`
- Experiment or demo infrastructure-as-code best practices

---
