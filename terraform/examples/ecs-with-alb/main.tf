#
terraform {
  required_version = ">= 0.12"
}



provider "aws" {
  version = ">= 2.0.0"
  region  = var.aws_region

  
  allowed_account_ids = [var.aws_account_id]
}



module "ecs_cluster" {
  
  source = "../../modules/ecs-cluster"

  cluster_name = var.ecs_cluster_name

  
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
    Foo = "Bar"
  }

  custom_tags_ec2_instances = [
    {
      key                 = "Foo"
      value               = "Bar"
      propagate_at_launch = true
    },
  ]
}


data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    ecs_cluster_name = var.ecs_cluster_name
  }
}



module "alb" {
  source = "../../modules/ecs-alb"

  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region

  alb_name         = var.service_name
  environment_name = var.environment_name
  is_internal_alb  = false

  http_listener_ports                    = [80, 5000]
  

  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.alb_vpc_subnet_ids
}


resource "aws_s3_bucket" "s3_test_bucket" {
  bucket = "${lower(var.service_name)}-test-s3-bucket"
  region = var.aws_region
}

resource "aws_s3_bucket_object" "s3_test_file" {
  count   = var.skip_s3_test_file_creation ? 0 : 1
  bucket  = aws_s3_bucket.s3_test_bucket.id
  key     = var.s3_test_file_name
  content = "world!"
}



resource "aws_iam_policy" "access_test_s3_bucket" {
  name   = "${var.service_name}-s3-test-bucket-access"
  policy = data.aws_iam_policy_document.access_test_s3_bucket.json
}

data "aws_iam_policy_document" "access_test_s3_bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_test_bucket.arn}/${var.s3_test_file_name}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.s3_test_bucket.arn]
  }
}

resource "aws_iam_policy_attachment" "access_test_s3_bucket" {
  name       = "${var.service_name}-s3-test-bucket-access"
  policy_arn = aws_iam_policy.access_test_s3_bucket.arn
  roles      = [module.ecs_service.ecs_task_iam_role_name]
}



# This template_file defines the Docker containers we want to run in our ECS Task
data "template_file" "ecs_task_container_definitions" {
  template = file("${path.module}/containers/container-definition.json")

  vars = {
    container_name = var.container_name
    # For this example, we run the Docker container defined under examples/example-docker-image.
    image               = "gruntwork/docker-test-webapp"
    version             = "latest"
    server_text         = var.server_text
    aws_region          = var.aws_region
    s3_test_file        = "s3://${aws_s3_bucket.s3_test_bucket.id}/${var.s3_test_file_name}"
    cpu                 = 512
    memory              = var.container_memory
    container_http_port = var.container_http_port
    command             = "[${join(",", formatlist("\"%s\"", var.container_command))}]"
    boot_delay_seconds  = var.container_boot_delay_seconds
  }
}



data "aws_route53_zone" "sample" {
  name = var.route53_hosted_zone_name
  tags = var.route53_tags
}

resource "aws_route53_record" "alb_endpoint" {
  zone_id = data.aws_route53_zone.sample.zone_id
  name    = "${var.ecs_cluster_name}.${data.aws_route53_zone.sample.name}"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_hosted_zone_id
    evaluate_target_health = true
  }
}



module "ecs_service" {
  
  source = "../../modules/ecs-alb"

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

  
  health_check_grace_period_seconds = 15

  alb_arn            = module.alb.alb_arn
  alb_container_name = var.container_name
  alb_container_port = var.container_http_port

  use_auto_scaling                 = false
  enable_ecs_deployment_check      = var.enable_ecs_deployment_check
  deployment_check_timeout_seconds = var.deployment_check_timeout_seconds
}


resource "aws_alb_listener_rule" "host_based_example" {
  
  listener_arn = module.alb.http_listener_arns["80"]

  priority = 95

  action {
    type             = "forward"
    target_group_arn = module.ecs_service.target_group_arn
  }

  condition {
    field  = "host-header"
    values = ["*.${var.route53_hosted_zone_name}"]
  }
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
    values = ["/static/*"]
  }
}


resource "aws_alb_listener_rule" "host_based_path_based_example" {
  
  listener_arn = module.alb.http_listener_arns["5000"]

  priority = 105

  action {
    type             = "forward"
    target_group_arn = module.ecs_service.target_group_arn
  }

  condition {
    field  = "host-header"
    values = ["*.acme.com"]
  }

  condition {
    field  = "path-pattern"
    values = ["/static/*"]
  }
}
