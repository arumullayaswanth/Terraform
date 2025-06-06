# Terraform Project: RDS MySQL with Remote Null Resource

## Overview

This project automates:

- A VPC with public and private subnets
- A Bastion EC2 instance to act as a jump server
- A private RDS MySQL instance
- A null_resource with remote-exec that SSHs into the Bastion host and runs init.sql

---

## Folder Structure

terraform-rds-remote-null/
├── main.tf
├── init.sql
├── outputs.tf
├── README.md

---

## Pre-Requisites

- Terraform installed
- AWS CLI configured (run `aws configure`)
- SSH key pair available in `~/.ssh/id_rsa`

---

## Terraform Execution Steps

1. Initialize Terraform:

    terraform init

2. Check the plan:

    terraform plan

3. Apply the configuration:

    terraform apply --auto-approve

---

## Verification Steps

### 1. RDS Setup Verification

- Go to AWS Console > RDS > Databases
- Verify that the instance is:
  - In Available state
  - Using correct port (3306)
  - Correct subnet group and security group

---

## How to Check MySQL Tables on AWS RDS

### Prerequisites

- MySQL client installed
- RDS instance must be running
- Use the credentials and outputs from Terraform:
  - Host: RDS Endpoint
  - Port: 3306
  - Username: admin
  - Password: Admin1234!
  - Database: mydb

---

## Accessing from the Bastion Host

### Step 1: SSH into Bastion Host

    ssh -i ~/.ssh/id_rsa ec2-user@<BASTION_PUBLIC_IP>

### Step 2: Check Remote Files

    cd /tmp
    ls
    cat creds.json
    cat mysql.sh

### Step 3: Check Credentials

    jq . /tmp/creds.json

Expected output:

    {
      "dbname": "mydb",
      "host": "my-rds.<region>.rds.amazonaws.com",
      "password": "Admin1234!",
      "username": "admin"
    }

### Step 4: Run the MySQL Script

    sh mysql.sh

You should see:

    Welcome to the MySQL monitor...
    mysql>

---

## MySQL Command Guide

### 1. Show All Databases:

    SHOW DATABASES;

### 2. Use a Database:

    USE mydb;

### 3. List Tables:

    SHOW TABLES;

### 4. Show Table Structure:

    DESCRIBE employees;
    SHOW COLUMNS FROM employees;

### 5. View Table Data:

    SELECT * FROM employees;
    SELECT * FROM employees LIMIT 5;
    SELECT name FROM employees;
    SELECT * FROM employees WHERE department_id = 2;

### 6. View Existing Views:

    SHOW FULL TABLES IN mydb WHERE Table_type = 'VIEW';
    SHOW CREATE VIEW employee_project_view;
    SELECT * FROM employee_project_view;

### 7. Custom Queries:

    SELECT e.name, d.name AS department
    FROM employees e
    JOIN departments d ON e.department_id = d.id;

    SELECT department_id, COUNT(*) FROM employees GROUP BY department_id;

### 8. Current User:

    SELECT USER();

### 9. Current Database:

    SELECT DATABASE();

### 10. Exit MySQL:

    exit;
    -- or --
    \q

---

## Clean Up

To destroy the infrastructure:

    terraform destroy --auto-approve

---

## Author

Arumulla Yaswanth Reddy  
Project: Terraform RDS with Remote SQL Execution
