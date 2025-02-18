terraform {
  backend "s3" {
    bucket          = "terraform-backend-hc-devops-challenge"
    key             = "dev/terraform.tfstate"
    region          = "eu-central-1"
    dynamodb_table  = "terraform-state-lock"
  }
}