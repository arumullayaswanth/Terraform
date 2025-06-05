# Output the RDS endpoint (includes port, used for connection)
output "rds_endpoint" {
  description = "The endpoint of the MySQL RDS instance"
  value       = aws_db_instance.mysql.endpoint  # Example: terraform-xyz.rds.amazonaws.com:3306
}

# Output the RDS address (hostname only, no port)
output "rds_address" {
  description = "The address (hostname) of the MySQL RDS instance"
  value       = aws_db_instance.mysql.address   # Example: terraform-xyz.rds.amazonaws.com
}

# Output the DB subnet group name used for the RDS instance
output "db_subnet_group" {
  description = "The subnet group name used for the RDS instance"
  value       = aws_db_subnet_group.default.name  # Should be: default-subnet-group
}

# Output the ID of the created VPC
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.vpc.id  # VPC ID like: vpc-0abc123def456
}

# Output the ID of the security group used for RDS
output "rds_security_group_id" {
  description = "The security group ID used for RDS"
  value       = aws_security_group.rds_sg.id  # SG ID like: sg-0abc123def456
}
