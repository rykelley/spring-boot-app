terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.0.0"
  region  = var.aws_region

}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  cluster_name = var.ecs_cluster_name

  # Make the max size twice the min size to allow for rolling out updates to the cluster without downtime
  cluster_min_size = 2
  cluster_max_size = 4

  cluster_instance_ami          = var.ecs_cluster_instance_ami
  cluster_instance_type         = var.ecs_cluster_instance_type
  cluster_instance_keypair_name = var.ecs_cluster_instance_keypair_name
  cluster_instance_user_data    = data.template_file.user_data.rendered

  vpc_id                           = var.vpc_id
  vpc_subnet_ids                   = var.ecs_cluster_vpc_subnet_ids
  allow_ssh_from_security_group_id = ""
  allow_ssh                        = false

  alb_security_group_ids     = [module.alb.alb_security_group_id]
  num_alb_security_group_ids = 1

  custom_tags_security_group = {
    Name = "ECS"
  }

  custom_tags_ec2_instances = [
    {
      key                 = "Name"
      value               = "ecs-cluster"
      propagate_at_launch = true
    },
  ]
}

module "alb" {
  source = "../../modules/alb"

  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region

  alb_name         = var.service_name
  environment_name = var.environment_name
  is_internal_alb  = false

  http_listener_ports                    = [80, 5000]
  https_listener_ports_and_ssl_certs     = []
  https_listener_ports_and_acm_ssl_certs = []
  #ssl_policy                             = "ELBSecurityPolicy-TLS-1-1-2017-01"

  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.alb_vpc_subnet_ids
}
