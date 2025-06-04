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
