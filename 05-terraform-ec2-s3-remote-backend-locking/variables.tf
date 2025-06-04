variable "ami" {
  default = "ami-085ad6ae776d8f09c"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "ec2test"
}

variable "ec2_name_tag" {
  default = "dev"
}

variable "ec2_az" {
  default = "us-east-1a"
}

variable "bucket_name" {
  default = "multicloudnareshitveera"
}

variable "state_bucket" {
  default = "yaswanthalure"
}

variable "dynamodb_table" {
  default = "terraform-state-lock-dynamo"
}
