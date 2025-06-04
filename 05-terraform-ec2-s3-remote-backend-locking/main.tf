resource "aws_instance" "example" {
  ami               = var.ami
  instance_type     = var.instance_type
  key_name          = var.key_name
  availability_zone = var.ec2_az

  tags = {
    Name = var.ec2_name_tag
  }
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = var.bucket_name
}
