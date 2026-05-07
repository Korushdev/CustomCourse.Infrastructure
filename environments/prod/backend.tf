terraform {
  backend "s3" {
    bucket         = "terraform-state-792052232996-eu-west-2-an"
    key            = "custom-course/prod/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}