# Specify the AWS provider and region
provider "aws" {
  region = var.region # The AWS region is loaded from variables.tf
}
