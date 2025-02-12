provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source = "../../modules/networking"

  environment         = "dev"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_count = 1
}
