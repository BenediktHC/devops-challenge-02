provider "aws" {
    region = "eu-central-1"
}

module "vpc" {
  source = "../../modules/networking"

  environment         = "prod"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_count = 2
}

module "compute" {
  source = "../../modules/compute"

  environment           = "prod"
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_id     = module.vpc.private_subnet_id
  instance_type         = "t2.micro"
  create_reverse_proxy  = true
}