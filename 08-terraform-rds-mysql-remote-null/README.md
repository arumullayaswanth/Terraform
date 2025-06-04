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
