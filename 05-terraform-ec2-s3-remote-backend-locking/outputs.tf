output "ec2_instance_id" {
  value = aws_instance.example.id
}

output "bucket_name" {
  value = aws_s3_bucket.code_bucket.bucket
}
