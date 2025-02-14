provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source                  = "../../modules/networking"
  environment            = "dev"
  vpc_cidr               = "10.0.0.0/16"
  public_subnet_count    = 1
  nat_network_interface_id = module.compute.web_eni_id
}

module "compute" {
  source = "../../modules/compute"

  environment         = "dev"
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_id   = module.vpc.private_subnet_id
  private_subnet_cidr = module.vpc.private_subnet_cidr
  instance_type       = "t2.micro"
}