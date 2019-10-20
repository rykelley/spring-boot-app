

terraform {
  required_version = ">= 0.12"
}



provider "aws" {

  region = var.aws_region
}


module "vpc_app_ecs" {

  source = "../../modules/vpc"

  vpc_name   = var.vpc_name
  aws_region = var.aws_region


  cidr_block = "10.0.0.0/18"


  num_nat_gateways = 1


  public_subnet_cidr_blocks = {}

  private_app_subnet_cidr_blocks = {}


  custom_tags = {
    name = "subnets"
  }

  public_subnet_custom_tags = {
    public-name = "public-subnets"
  }

  private_app_subnet_custom_tags = {
    private-name = "private-app"
  }

  nat_gateway_custom_tags = {
    nat-name = "nat-gateway"
  }
}
