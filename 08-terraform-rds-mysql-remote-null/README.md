# 🚀 Terraform RDS MySQL with Remote Null Resource (Step-by-Step Guide)

## 📘 Overview

This project provisions the following using Terraform:

- A **custom VPC** with public/private subnets  
- An **EC2 Bastion Host** for secure MySQL access  
- A **private RDS MySQL instance**  
- **Remote execution** using `null_resource` to run SQL from the Bastion.

---

## 🧰 Prerequisites

Before running this project, ensure the following:

1. ✅ **Terraform** installed: [Install Terraform](https://developer.hashicorp.com/terraform/install)
2. ✅ **AWS CLI** installed and configured:  
   ```bash
   aws configure
   ```
3. ✅ An SSH key pair available at:  
   - Private key: `~/.ssh/id_rsa`  
   - Public key: `~/.ssh/id_rsa.pub`

---

## 📂 Folder Structure

```
terraform-rds-remote-null/
├── main.tf         # Terraform configurations
├── init.sql        # SQL schema/data to run after RDS setup
├── outputs.tf      # Output variables
├── README.md       # This file
```

---

## 🪄 Step 1: Initialize Terraform

Navigate into the project folder and initialize:

```bash
cd terraform-rds-remote-null/
terraform init
```

---

## 🔍 Step 2: Preview Infrastructure

This shows what Terraform will create:

```bash
terraform plan
```

---

## ⚙️ Step 3: Apply Configuration

Deploy all resources:

```bash
terraform apply --auto-approve
```

---

## ✅ Step 4: Validate RDS Deployment

Once `apply` completes:

1. Go to **AWS Console** → **RDS** → **Databases**
2. Confirm:
   - Status: `Available`
   - Endpoint visible
   - Port: `3306`
   - Proper subnet group and security groups

---

## 🔐 Step 5: Access EC2 Bastion Host

1. Copy the `bastion_public_ip` from the Terraform output.

2. SSH into the Bastion host:

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<BASTION_PUBLIC_IP>
```

---

## 🧪 Step 6: Validate MySQL Setup

### 1. Go to temp directory:

```bash
cd /tmp
```

### 2. List and check credentials/scripts:

```bash
ls
cat creds.json
cat mysql.sh
```

### 3. Verify JSON content:

```bash
jq . /tmp/creds.json
```

Sample output:
```json
{
  "dbname": "mydb",
  "host": "my-rds.<region>.rds.amazonaws.com",
  "password": "Admin1234!",
  "username": "admin"
}
```

---

## 🔄 Step 7: Connect to MySQL

Run the MySQL script:

```bash
sh mysql.sh
```

Expected result:
```
Welcome to the MySQL monitor...
mysql>
```

---

## 🧾 Step 8: Run SQL Queries

### Show databases:
```sql
SHOW DATABASES;
```

### Use your database:
```sql
USE mydb;
```

### List tables:
```sql
SHOW TABLES;
```

### Describe table:
```sql
DESCRIBE employees;
```

### Select data:
```sql
SELECT * FROM employees;
SELECT name FROM employees;
```

### Filter data:
```sql
SELECT * FROM employees WHERE department_id = 2;
```

### Views:
```sql
SHOW FULL TABLES IN mydb WHERE Table_type = 'VIEW';
SELECT * FROM employee_project_view;
```

### Custom query:
```sql
SELECT e.name, d.name AS department
FROM employees e
JOIN departments d ON e.department_id = d.id;
```

---

## 🚪 Step 9: Exit MySQL

```sql
exit;
-- or --
\q
```

---

## 🧹 Step 10: Destroy Infrastructure (Optional)

To clean up all resources:

```bash
terraform destroy --auto-approve
```

---

## 📬 Need Help?

Let me know if you want:

- ✅ Full Terraform config (`main.tf`, `init.sql`, etc.)
- ✅ Architecture diagram
- ✅ GitHub-ready version

Happy automating! ⚡
