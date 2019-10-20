terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.0.0"
  region  = var.aws_region

}

module "ecr-repos" {
  source = "../../modules/ecr-repos"

  aws_region = var.aws_region
  repo_names = var.repo_names
}
