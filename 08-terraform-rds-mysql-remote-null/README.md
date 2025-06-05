# Terraform Project: RDS MySQL with Remote Null Resource

## 📌 Overview

This project automates the setup of:

* A VPC with public/private subnets.
* A Bastion EC2 instance to act as a jump server.
* A private RDS MySQL instance.
* A `null_resource` with `remote-exec` to SSH into the Bastion and initialize the MySQL database remotely using `init.sql`.

---

## 💂 Folder Structure

```bash
terraform-rds-remote-null/
├── main.tf
├── init.sql
├── outputs.tf
├── README.md
```

---

## 🔧 Pre-Requisites

* Terraform installed
* AWS CLI configured (`aws configure`)
* An SSH key pair created locally (e.g. `~/.ssh/id_rsa`)

---

## 1⃣ main.tf

Terraform configuration includes:

* Provider config
* VPC, Subnet, Gateway, Route Table setup
* EC2 Bastion
* RDS MySQL
* Null resource with SSH and SQL execution logic

*(See full ****`main.tf`**** in your workspace for detailed code)*

---

## 2⃣ init.sql

```sql
-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
  dept_id INT AUTO_INCREMENT PRIMARY KEY,
  dept_name VARCHAR(100) NOT NULL UNIQUE
);

-- Create employees table
CREATE TABLE IF NOT EXISTS employees (
  emp_id INT AUTO_INCREMENT PRIMARY KEY,
  emp_name VARCHAR(100) NOT NULL,
  dept_id INT,
  salary DECIMAL(10, 2),
  hire_date DATE,
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Create projects table
CREATE TABLE IF NOT EXISTS projects (
  project_id INT AUTO_INCREMENT PRIMARY KEY,
  project_name VARCHAR(100) NOT NULL,
  start_date DATE,
  end_date DATE
);

-- Create assignments table
CREATE TABLE IF NOT EXISTS assignments (
  assignment_id INT AUTO_INCREMENT PRIMARY KEY,
  emp_id INT,
  project_id INT,
  assigned_date DATE,
  role VARCHAR(100),
  FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
  FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

-- Create employee_log table
CREATE TABLE IF NOT EXISTS employee_log (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  emp_name VARCHAR(100),
  log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger to log insertions to employees
DELIMITER //
CREATE TRIGGER log_employee_insert
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
  INSERT INTO employee_log (emp_name) VALUES (NEW.emp_name);
END;//
DELIMITER ;

-- Create a stored procedure
DELIMITER //
CREATE PROCEDURE GetEmployeesByDept(IN dept_name_param VARCHAR(100))
BEGIN
  SELECT e.emp_name, e.salary FROM employees e
  JOIN departments d ON e.dept_id = d.dept_id
  WHERE d.dept_name = dept_name_param;
END;//
DELIMITER ;

-- Create a view
CREATE OR REPLACE VIEW employee_project_view AS
SELECT e.emp_name, d.dept_name, p.project_name, a.assigned_date, a.role
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN assignments a ON e.emp_id = a.emp_id
JOIN projects p ON a.project_id = p.project_id;

-- Insert data
INSERT INTO departments (dept_name) VALUES ('HR'), ('Engineering'), ('Sales'), ('Marketing'), ('Finance');

INSERT INTO employees (emp_name, dept_id, salary, hire_date) VALUES
('Alice', 1, 70000.00, '2020-01-15'),
('Bob', 2, 90000.00, '2019-07-23'),
('Charlie', 3, 60000.00, '2021-03-12'),
('Diana', 2, 95000.00, '2018-11-04'),
('Edward', 4, 80000.00, '2022-05-01');

INSERT INTO projects (project_name, start_date, end_date) VALUES
('Project Apollo', '2023-01-01', '2023-12-31'),
('Project Zephyr', '2024-02-15', NULL),
('Project Titan', '2024-03-01', '2024-08-31');

INSERT INTO assignments (emp_id, project_id, assigned_date, role) VALUES
(2, 1, '2023-01-05', 'Lead Developer'),
(4, 1, '2023-01-10', 'QA Engineer'),
(3, 2, '2024-02-20', 'Sales Representative'),
(5, 3, '2024-03-02', 'Marketing Lead');
```

---

## ✅ Execution Steps

### Step 1: Initialize Terraform

```bash
terraform init
```

### Step 2: Review Plan

```bash
terraform plan
```

### Step 3: Apply Configuration

```bash
terraform apply
```

---

## ✅ Verification Steps

### 🔹 Step 1: Verify RDS Setup in AWS Console

1. Log in to **AWS Console**
2. Navigate to **RDS → Databases**
3. Ensure the **RDS instance is available**
4. Check the following:

   * Endpoint
   * Port (3306)
   * Subnet Group
   * Security Group allows MySQL traffic




# 📘 How to Check MySQL Tables on AWS RDS

After deploying your infrastructure using Terraform and initializing your MySQL database with `init.sql`, you can use the following steps to inspect and verify your tables.

---

## 🔧 Prerequisites

- MySQL client installed on your system
- RDS instance up and running
- Credentials from your Terraform deployment:
  - **Host**: RDS endpoint from Terraform output
  - **Port**: 3306 (default for MySQL)
  - **Username**: `admin`
  - **Password**: `Admin1234!`
  - **Database**: `mydb`

---

## 🚀 Step-by-Step Instructions



### 🔹 Step 2: Connect to EC2 Bastion

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<EC2-PUBLIC-IP>
```

---

### 🔹 Step 3: Install MySQL Client (if not installed)

```bash
sudo yum install -y mysql
```

---

### 🔹 Step 4: Connect to RDS from Bastion

```bash
mysql -h <RDS-ENDPOINT> -P 3306 -u admin -p
```

---


### 3. Enter the Database

Once connected:

```sql
USE mydb;
```

Expected Output:

```
+----------------+
| Tables_in_mydb |
+----------------+
| assignments    |
| departments    |
| employees      |
| projects       |
+----------------+
```

---

## 📂 Inspect Your Tables

### Show All Tables

```sql
SHOW TABLES;
```

### Describe Table Structure

```sql
DESCRIBE employees;
DESCRIBE departments;
DESCRIBE projects;
DESCRIBE assignments;
DESCRIBE employee_log;
```

### View Table Contents

```sql
SELECT * FROM employees;
SELECT * FROM departments;
SELECT * FROM projects;
SELECT * FROM assignments;
SELECT * FROM employee_log;
```
### 🔹 Step 6: Query Data

```sql
SELECT * FROM departments;
SELECT emp_name, salary FROM employees;
SELECT * FROM assignments WHERE role = 'Lead Developer';
```

---

### 🔹 Step 7: Join Query Example

```sql
SELECT e.emp_name, p.project_name
FROM employees e
JOIN assignments a ON e.emp_id = a.emp_id
JOIN projects p ON a.project_id = p.project_id;
```

Expected Output:
---

## 🔒 Exit MySQL

```sql
\q
```

---

## 🧠 Troubleshooting

- **Access Denied**: Double-check username/password and security group rules.
- **Host Not Found**: Ensure RDS is available and publicly accessible.
- **No Tables Shown**: Ensure `init.sql` was executed successfully via Terraform provisioner.

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


