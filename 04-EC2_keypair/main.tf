
resource "aws_key_pair" "name" {
  key_name = "public"
  public_key = file("C:/Users/Yaswanth Reddy/.ssh/id_ed25519.pub")   #here you need to define public key file path

}

resource "aws_instance" "dev" {
    ami = "ami-02457590d33d576c3"
    instance_type = "t2.micro"
    key_name = aws_key_pair.name.key_name
    tags = {
      Name = "keys"
    }

}
