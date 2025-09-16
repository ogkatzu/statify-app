terraform {
  backend "s3" {
    bucket  = "your-terraform-bucket"
    key     = "terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}