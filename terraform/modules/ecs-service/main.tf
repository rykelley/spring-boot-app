# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A DOCKER APP WITH AN APPLICATION LOAD BALANCER IN FRONT OF IT
# These templates show an example of how to run a Docker app on top of Amazon's EC2 Container Service (ECS) with an
# Application Load Balancer (ALB) routing traffic to the app.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  version = ">= 2.0.0"
  region  = var.aws_region

  # Only this AWS Account ID may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ECS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "ecs_cluster" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-ecs.git//modules/ecs-cluster?ref=v1.0.8"
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

# Create the User Data script that will run on boot for each EC2 Instance in the ECS Cluster.
# - This script will configure each instance so it registers in the right ECS cluster and authenticates to the proper
#   Docker registry.
data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    ecs_cluster_name = var.ecs_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALB TO ROUTE TRAFFIC ACROSS THE ECS TASKS
# Typically, this would be created once for use with many different ECS Services.
# ---------------------------------------------------------------------------------------------------------------------

module "alb" {
  source = "../alb"

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




# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ECS TASK DEFINITION FORMATTED AS JSON TO PASS TO THE ECS SERVICE
# This tells the ECS Service which Docker image to run, how much memory to allocate, and every other aspect of how the
# Docker image should run. Note that this resoure merely generates a JSON file; the actual AWS resource is created in
# module.ecs_service
# ---------------------------------------------------------------------------------------------------------------------

# This template_file defines the Docker containers we want to run in our ECS Task
data "template_file" "ecs_task_container_definitions" {
  template = file("${path.module}/containers/container-definition.json")

  vars = {
    container_name = var.container_name
    # For this example, we run the Docker container defined under examples/example-docker-image.
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



# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ECS SERVICE
# In Amazon ECS, Docker containers are run as "ECS Tasks", typically as part of an "ECS Service".
# ---------------------------------------------------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ALB LISTENER RULES ASSOCIATED WITH THIS ECS SERVICE
# When an HTTP request is received by the ALB, how will the ALB know to route that request to this particular ECS Service?
# The answer is that we define ALB Listener Rules (https://goo.gl/vQv8oQ) that can route a request to a specific "Target
# Group" that contains "Targets". Each Target is actually an ECS Task (which is really just a Docker container). An ECS Service
# is ultimately made up of zero or more ECS Tasks.
#
# For example purposes, we will define one path-based routing rule and one host-based routing rule.
# ---------------------------------------------------------------------------------------------------------------------

# EXAMPLE OF A HOST-BASED LISTENER RULE
# Host-based Listener Rules are used when you wish to have a single ALB handle requests for both foo.acme.com and
# bar.acme.com. Using a host-based routing rule, the ALB can route each inbound request to the desired Target Group.
resource "aws_alb_listener_rule" "host_based_example" {
  # Get the Listener ARN associated with port 80 on the ALB
  # In other words, this ALB has a Listener that listens for incoming traffic on port 80. That Listener has a unique
  # Amazon Resource Name (ARN), which we must pass to this rule so it knows which ALB Listener to "attach" to. Fortunately,
  # Our ALB module outputs values like http_listener_arns, https_listener_non_acm_cert_arns, and https_listener_acm_cert_arns
  # so that we can easily look up the ARN by the port number.
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

# EXAMPLE OF A PATH-BASED LISTENER RULE
# Path-based Listener Rules are used when you wish to route all requests received by the ALB that match a certain
# "path" pattern to a given ECS Service. This is useful if you have one service that should receive all requests sent
# to /api and another service that receives requests sent to /customers.
resource "aws_alb_listener_rule" "path_based_example" {
  # Get the Listener ARN associated with port 5000 on the ALB
  # In other words, this ALB has a Listener that listens for incoming traffic on port 80. That Listener has a unique
  # Amazon Resource Name (ARN), which we must pass to this rule so it knows which ALB Listener to "attach" to. Fortunately,
  # Our ALB module outputs values like http_listener_arns, https_listener_non_acm_cert_arns, and https_listener_acm_cert_arns
  # so that we can easily look up the ARN by the port number.
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