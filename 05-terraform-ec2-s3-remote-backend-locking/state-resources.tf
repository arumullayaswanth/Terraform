# 1. Create the S3 bucket
resource "aws_s3_bucket" "tf_backend" {
  bucket = var.state_bucket
}

# 2. Enable versioning
resource "aws_s3_bucket_versioning" "tf_backend_versioning" {
  bucket = aws_s3_bucket.tf_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_backend_encryption" {
  bucket = aws_s3_bucket.tf_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_dynamodb_table" "tf_lock" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
