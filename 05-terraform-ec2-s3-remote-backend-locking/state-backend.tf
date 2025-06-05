#Temporarily Comment Out the Backend Block the backend is defined, comment out this block for now:
 
 terraform {
   backend "s3" {
     bucket         = "terraform-state-lock-yaswanth6758546"
     key            = "terraform.tfstate"
     region         = "us-east-1"
     dynamodb_table = "terraform-state-lock-dynamo"
     encrypt        = true
   }
 }
