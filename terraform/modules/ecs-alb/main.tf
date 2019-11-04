terraform {
    required_version = ">=0.12"
}

resource "aws_ecs_service" "service_asg" {
    depends_on = [
        aws_iam_resource_policy.ecs_service_scheduler,
        null_resource.alb._exists,
        ]
  name = var.service_name
  cluster = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.task.arn


  iam_role = aws_iam_role.ecs_service_scheduler.arn

  desired_count                      = var.desired_number_of_tasks
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  ordered_placement_strategy {
      type = var.placement_strategy_type
      field = var.placement_strategy_field
  }
    placement_constraints {
        type = var.placement_constraints_type
        expression = var.placement_constraints_expression
    }

    load_balancer {
    target_group_arn = data.template_file.alb_target_group_arn.rendered
    container_name   = var.alb_container_name
    container_port   = var.alb_container_port
  }

 
  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_task_definition" "task" {
    family = var.serivce_name
    container_definitions = var.ecr_task_container_definitions
    task_role_arn = aws_iam_role_.ecs_task.task_arn
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    network = var.ecs_task_definition_network_mode

  dynamic "volume" {
      for_each = var.volumes
      content {
          name = volume.value.name
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

resource "aws_alb_target_group" "ecs_service_with_sticky_sessions" {
  count = var.use_alb_sticky_sessions ? 1 : 0

  
  depends_on = [null_resource.alb_exists]

  name     = local.alb_target_group_name
  port     = 443
  protocol = var.alb_target_group_protocol
  vpc_id   = var.vpc_id

  deregistration_delay = var.alb_target_group_deregistration_delay

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

# Define the IAM Policy as required per Per https://goo.gl/mv8bJ4.
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

# Define the Assume Role IAM Policy Document for the ECS Service Scheduler IAM Role
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

resource "aws_iam_role" "ecs_service_autoscaling_role" {
  count = var.use_auto_scaling ? 1 : 0

  name               = "${var.service_name}-${var.environment_name}-autoscaling"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_autoscaling_role_trust_policy[0].json

  
  provisioner "local-exec" {
    command = "echo 'Sleeping for 15 seconds to wait for IAM role to be created'; sleep 15"
  }
}

data "aws_iam_policy_document" "ecs_service_autoscaling_role_trust_policy" {
  count = var.use_auto_scaling ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_service_autoscaling_policy" {
  count = var.use_auto_scaling ? 1 : 0

  name   = "enable-autoscaling"
  role   = aws_iam_role.ecs_service_autoscaling_role[0].name
  policy = data.aws_iam_policy_document.ecs_service_autoscaling_policy.json
}


data "aws_iam_policy_document" "ecs_service_autoscaling_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarms",
    ]

    resources = ["*"]
  }
}

resource "aws_appautoscaling_target" "appautoscaling_target" {
  count = var.use_auto_scaling ? 1 : 0

  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  resource_id = "service/${var.ecs_cluster_name}/${var.service_name}"
  role_arn    = aws_iam_role.ecs_service_autoscaling_role[0].arn

  min_capacity = var.min_number_of_tasks
  max_capacity = var.max_number_of_tasks

  depends_on = [
    aws_ecs_service.service_with_auto_scaling,
    
  ]
}

data "template_file" "alb_target_group_arn" {
  
  template = element(
    concat(
      aws_alb_target_group.ecs_service_with_sticky_sessions.*.arn,
      aws_alb_target_group.ecs_service_without_sticky_sessions.*.arn,
    ),
    0,
  )
}

resource "null_resource" "alb_exists" {
  triggers = {
    alb_name = var.alb_arn
  }
}

