provider "aws" {

  region = var.aws_region


  version = "~> 2.6"
}

resource "aws_ecr_repository" "repos" {
  name = var.repo_names
}
