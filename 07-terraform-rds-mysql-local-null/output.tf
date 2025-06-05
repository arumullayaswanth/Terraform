# RDS MySQL endpoint
output "rds_endpoint" {
  description = "The endpoint of the MySQL RDS instance"
  value       = aws_db_instance.mysql.endpoint
}

# RDS address (host)
output "rds_address" {
  description = "The address (hostname) of the MySQL RDS instance"
  value       = aws_db_instance.mysql.address
}

# RDS database name
output "rds_database_name" {
  description = "The database name created in RDS"
  value       = aws_db_instance.mysql.name
}

# Subnet group name
output "db_subnet_group" {
  description = "The subnet group name used for the RDS instance"
  value       = aws_db_subnet_group.default.name
}

# VPC ID
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.vpc.id
}

# Security group ID
output "rds_security_group_id" {
  description = "The security group ID used for RDS"
  value       = aws_security_group.rds_sg.id
}
