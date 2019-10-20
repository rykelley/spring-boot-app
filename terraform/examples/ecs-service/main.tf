
terraform {
  required_version = ">= 0.12"
}



provider "aws" {
  version = ">= 2.0.0"
  region  = var.aws_region

  # Only this AWS Account ID may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    ecs_cluster_name = var.ecs_cluster_name
  }
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
  ssl_policy                             = "ELBSecurityPolicy-TLS-1-1-2017-01"

  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.alb_vpc_subnet_ids
}







data "template_file" "ecs_task_container_definitions" {
  template = file("${path.module}/containers/container-definition.json")

  vars = {
    container_name = var.container_name

    image               = "522052662196.dkr.ecr.us-east-1.amazonaws.com/spring-boot-app"
    version             = "latest"
    aws_region          = var.aws_region
    cpu                 = 512
    memory              = var.container_memory
    container_http_port = var.container_http_port
    command             = "[${join(",", formatlist("\"%s\"", var.container_command))}]"
    boot_delay_seconds  = var.container_boot_delay_seconds
  }
}


module "ecs_service" {

  source = "../../modules/ecs-service"

  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region

  service_name     = var.service_name
  environment_name = var.environment_name

  vpc_id                         = var.vpc_id
  ecs_cluster_name               = module.ecs_cluster.ecs_cluster_name
  ecs_cluster_arn                = module.ecs_cluster.ecs_cluster_arn
  ecs_task_container_definitions = data.template_file.ecs_task_container_definitions.rendered

  desired_number_of_tasks = var.desired_number_of_tasks
  min_number_of_tasks     = var.min_number_of_tasks
  max_number_of_tasks     = var.max_number_of_tasks

  # Give the container 15 seconds to boot before having the ALB start checking health
  health_check_grace_period_seconds = 15

  alb_slow_start = 30

  alb_arn            = module.alb.alb_arn
  alb_container_name = var.container_name
  alb_container_port = var.container_http_port

  use_auto_scaling                 = false
  enable_ecs_deployment_check      = var.enable_ecs_deployment_check
  deployment_check_timeout_seconds = var.deployment_check_timeout_seconds
}

resource "aws_alb_listener_rule" "path_based_example" {

  listener_arn = module.alb.http_listener_arns["5000"]

  priority = 100

  action {
    type             = "forward"
    target_group_arn = module.ecs_service.target_group_arn
  }

  condition {
    field  = "path-pattern"
    values = ["/services/*"]
  }
}
