# Terraform Project: AWS RDS MySQL with Null Resource and Init SQL Script

## Overview

This project deploys:

* AWS RDS MySQL instance
* Null resource that waits for RDS to be ready, installs MySQL client, and runs SQL init script with schema + data
* Uses Terraform provisioners (`local-exec`) for remote SQL execution via MySQL client

---

## Folder Structure

```
terraform-rds-mysql-null/
├── main.tf
├── init.sql
├── README.md
```

---

## main.tf

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_db_subnet_group" "default" {
  name       = "default-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "Default subnet group"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow MySQL inbound"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # For demo only, restrict in prod!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "Admin1234!"  # Change to secure password
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = true
  multi_az             = false
}

resource "null_resource" "init_db" {
  depends_on = [aws_db_instance.mysql]

  provisioner "local-exec" {
    command = <<EOT
      # Wait for RDS to be available
      for i in {1..30}; do
        nc -zvw3 ${aws_db_instance.mysql.address} 3306 && break
        echo "Waiting for MySQL to be available..."
        sleep 10
      done

      # Run the init.sql script to create schema and insert data
      mysql -h ${aws_db_instance.mysql.address} -P 3306 -u admin -pAdmin1234! mydb < init.sql
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
```

---

## init.sql

```sql
-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
  dept_id INT AUTO_INCREMENT PRIMARY KEY,
  dept_name VARCHAR(100) NOT NULL UNIQUE
);

-- Create employees table with foreign key to departments
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

-- Create assignments table to link employees and projects (many-to-many)
CREATE TABLE IF NOT EXISTS assignments (
  assignment_id INT AUTO_INCREMENT PRIMARY KEY,
  emp_id INT,
  project_id INT,
  assigned_date DATE,
  role VARCHAR(100),
  FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
  FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

-- Insert into departments
INSERT INTO departments (dept_name) VALUES
('HR'), ('Engineering'), ('Sales'), ('Marketing');

-- Insert into employees
INSERT INTO employees (emp_name, dept_id, salary, hire_date) VALUES
('Alice', 1, 70000.00, '2020-01-15'),
('Bob', 2, 90000.00, '2019-07-23'),
('Charlie', 3, 60000.00, '2021-03-12'),
('Diana', 2, 95000.00, '2018-11-04');

-- Insert into projects
INSERT INTO projects (project_name, start_date, end_date) VALUES
('Project Apollo', '2023-01-01', '2023-12-31'),
('Project Zephyr', '2024-02-15', NULL);

-- Insert into assignments
INSERT INTO assignments (emp_id, project_id, assigned_date, role) VALUES
(2, 1, '2023-01-05', 'Lead Developer'),
(4, 1, '2023-01-10', 'QA Engineer'),
(3, 2, '2024-02-20', 'Sales Representative');
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

---

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

### 🔹 Step 5: Verify Tables

```sql
USE mydb;
SHOW TABLES;
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

| emp\_name | project\_name  |
| --------- | -------------- |
| Bob       | Project Apollo |
| Diana     | Project Apollo |
| Charlie   | Project Zephyr |


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
