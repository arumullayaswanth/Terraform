variable "ami" {
    default = "ami-02457590d33d576c3"
  
}

variable "instance_type" {
    default = "t2.micro"
  
}

variable "key_name" {
    default = "public"
}

variable "ec2_name_tag" {
  default = "EC2-server"
}

variable "ec2_az" {
    default = "us-east-1a"
}

variable "bucker_name" {
    default = "yaswantharumulla523182"
}

variable "state_bucket" {
    default = "terraform-state-lock-yaswanth6758546"
  
}

variable "dynamodb_table" {
    default = "terraform-state-lock-dynamo"
  
}
