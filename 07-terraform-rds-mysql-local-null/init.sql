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
('HR'),
('Engineering'),
('Sales'),
('Marketing');

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

-- Query example: List all employees with their department names and salaries
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY e.emp_name;

-- Query example: List projects and assigned employees with roles
SELECT p.project_name, e.emp_name, a.role, a.assigned_date
FROM projects p
LEFT JOIN assignments a ON p.project_id = a.project_id
LEFT JOIN employees e ON a.emp_id = e.emp_id
ORDER BY p.project_name, e.emp_name;
