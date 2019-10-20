

terraform {
  
  required_version = ">= 0.12"
}


locals {
  alb_target_group_name      = var.alb_target_group_name == "" ? var.service_name : var.alb_target_group_name
  task_execution_name_prefix = var.custom_task_execution_name_prefix != "" ? var.custom_task_execution_name_prefix : var.service_name
}


resource "aws_ecs_service" "service_spring_boot" {
  count = ! var.use_auto_scaling ? 1 : 0
  depends_on = [
    aws_iam_role_policy.ecs_service_scheduler,
    null_resource.alb_exists,
  ]

  name            = var.service_name
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.task.arn


  iam_role = aws_iam_role.ecs_service_scheduler.arn

  desired_count                      = var.desired_number_of_tasks
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  ordered_placement_strategy {
    type  = var.placement_strategy_type
    field = var.placement_strategy_field
  }

  placement_constraints {
    type       = var.placement_constraint_type
    expression = var.placement_constraint_expression
  }

  load_balancer {
    target_group_arn = local.alb_target_group_arn
    container_name   = var.alb_container_name
    container_port   = var.alb_container_port
  }
}

resource "aws_ecs_task_definition" "task" {
  family                = var.service_name
  container_definitions = var.ecs_task_container_definitions
  task_role_arn         = aws_iam_role.ecs_task.arn
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  network_mode          = var.ecs_task_definition_network_mode

  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])

        content {
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
          scope         = lookup(docker_volume_configuration.value, "scope", null)
        }
      }
    }
  }
}



resource "aws_alb_target_group" "ecs_service_without_sticky_sessions" {
  count = ! var.use_alb_sticky_sessions ? 1 : 0


  depends_on = [null_resource.alb_exists]

  name     = local.alb_target_group_name
  port     = 80
  protocol = var.alb_target_group_protocol
  vpc_id   = var.vpc_id

  deregistration_delay = var.alb_target_group_deregistration_delay
  slow_start           = var.alb_slow_start

  health_check {
    interval            = var.health_check_interval
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }
}

resource "aws_alb_target_group" "ecs_service_with_sticky_sessions" {
  count = var.use_alb_sticky_sessions ? 1 : 0


  depends_on = [null_resource.alb_exists]

  name     = local.alb_target_group_name
  port     = 80
  protocol = var.alb_target_group_protocol
  vpc_id   = var.vpc_id

  deregistration_delay = var.alb_target_group_deregistration_delay
  slow_start           = var.alb_slow_start

  health_check {
    interval            = var.health_check_interval
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }

  stickiness {
    type            = var.alb_sticky_session_type
    cookie_duration = var.alb_sticky_session_cookie_duration
  }
}


resource "aws_iam_role" "ecs_service_scheduler" {
  name               = "${var.service_name}-${var.environment_name}-service-scheduler"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_scheduler_assume_role.json

  provisioner "local-exec" {
    command = "echo 'Sleeping for 15 seconds to wait for IAM role to be created'; sleep 15"
  }
}


data "aws_iam_policy_document" "ecs_service_scheduler_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy" "ecs_service_scheduler" {
  name   = "${var.service_name}-ecs-service-scheduler-policy"
  role   = aws_iam_role.ecs_service_scheduler.name
  policy = data.aws_iam_policy_document.ecs_service_scheduler.json
}


data "aws_iam_policy_document" "ecs_service_scheduler" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
    ]

    resources = ["*"]
  }
}


resource "aws_iam_role" "ecs_task" {
  name               = "${var.service_name}-${var.environment_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json


  provisioner "local-exec" {
    command = "echo 'Sleeping for 15 seconds to wait for IAM role to be created'; sleep 15"
  }
}


data "aws_iam_policy_document" "ecs_task" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = concat(list("ecs-tasks.amazonaws.com"), var.additional_task_assume_role_policy_principals)
    }
  }
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.task_execution_name_prefix}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json

  provisioner "local-exec" {
    command = "echo 'Sleeping for 15 seconds to wait for IAM role to be created'; sleep 15"
  }
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name   = "${local.task_execution_name_prefix}-task-excution-policy"
  policy = data.aws_iam_policy_document.ecs_task_execution_policy_document.json
}

data "aws_iam_policy_document" "ecs_task_execution_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy_attachment" "task_execution_policy_attachment" {
  name       = "${local.task_execution_name_prefix}-task-execution"
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
  roles      = [aws_iam_role.ecs_task_execution_role.name]
}


  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds to work around ecs service creation bug in Terraform' && sleep 30"
  }
}


locals {
  alb_target_group_arn = var.use_alb_sticky_sessions ? aws_alb_target_group.ecs_service_with_sticky_sessions[0].arn : aws_alb_target_group.ecs_service_without_sticky_sessions[0].arn
}


resource "null_resource" "alb_exists" {
  triggers = {
    alb_name = var.alb_arn
  }
}


locals {
  ecs_service_arn = element(
    concat(
      aws_ecs_service.service_with_auto_scaling.*.id,
      aws_ecs_service.service_without_auto_scaling.*.id,
    ),
    0,
  )

  ecs_service_task_definition_arn = element(
    concat(
      aws_ecs_service.service_with_auto_scaling.*.task_definition,
      aws_ecs_service.service_without_auto_scaling.*.task_definition,
    ),
    0,
  )

  ecs_service_desired_count = element(
    concat(
      aws_ecs_service.service_with_auto_scaling.*.desired_count,
      aws_ecs_service.service_without_auto_scaling.*.desired_count,
    ),
    0,
  )



  check_common_args = <<EOF
--loglevel ${var.deployment_check_loglevel} \
--aws-region ${var.aws_region} \
--ecs-cluster-arn ${var.ecs_cluster_arn} \
--check-timeout-seconds ${var.deployment_check_timeout_seconds}
EOF

}

resource "null_resource" "ecs_deployment_check" {
  count = var.enable_ecs_deployment_check ? 1 : 0

  // Run check if anything is deployed to the service
  triggers = {
    ecs_service_arn         = local.ecs_service_arn
    ecs_task_definition_arn = local.ecs_service_task_definition_arn
    desired_count           = local.ecs_service_desired_count
  }

  provisioner "local-exec" {
    command = <<EOF
${module.ecs_deployment_check_bin.path} \
  --ecs-service-arn ${local.ecs_service_arn} \
  --ecs-task-definition-arn ${local.ecs_service_task_definition_arn} \
  --min-active-task-count ${local.ecs_service_desired_count} \
  ${local.check_common_args}
EOF

  }
}
