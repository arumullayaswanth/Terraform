
output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP of Bastion Host"
}

output "rds_endpoint" {
  value       = aws_db_instance.mysql.address
  description = "RDS MySQL endpoint"
}

output "rds_secret_arn" {
  value       = aws_secretsmanager_secret.rds_secret.arn
  description = "ARN of the database credentials secret"
}
