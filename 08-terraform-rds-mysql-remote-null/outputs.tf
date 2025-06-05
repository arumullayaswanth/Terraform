output "bastion_public_ip" {
  description = "Public IP of the Bastion EC2 instance"
  value       = aws_instance.bastion.public_ip
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.mysql.port
}

output "rds_db_name" {
  description = "RDS MySQL DB Name"
  value       = aws_db_instance.mysql.name
}
