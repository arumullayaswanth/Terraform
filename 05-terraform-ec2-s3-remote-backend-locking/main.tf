resource "aws_key_pair" "name" {
  key_name = var.key_name
  public_key = file("C:/Users/Yaswanth Reddy/.ssh/id_ed25519.pub")

}


resource "aws_instance" "example" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = aws_key_pair.name.key_name
    availability_zone = var.ec2_az

    tags = {
      Name = var.ec2_name_tag
    }
  
}

resource "aws_s3_bucket" "code_bucket" {
    bucket = var.bucker_name
  
}
