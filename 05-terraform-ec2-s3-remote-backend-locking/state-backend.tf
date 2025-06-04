terraform {
  backend "s3" {
    bucket         = "veeranareshitdevopsss"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"
    encrypt        = true
  }
}
