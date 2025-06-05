
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.server.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.server.public_dns
}

output "ec2_id" {
  description = "Instance ID of the EC2 instance"
  value       = aws_instance.server.id
}
