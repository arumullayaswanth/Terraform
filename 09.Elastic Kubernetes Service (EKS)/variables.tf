# Define AWS region
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# VPC CIDR block
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Public Subnet 1
variable "public_subnet_1_cidr" {
  default = "10.0.1.0/24"
}

# Public Subnet 2
variable "public_subnet_2_cidr" {
  default = "10.0.2.0/24"
}

# Availability Zone for subnet 1
variable "availability_zone_1" {
  default = "us-east-1a"
}

# Availability Zone for subnet 2
variable "availability_zone_2" {
  default = "us-east-1b"
}
