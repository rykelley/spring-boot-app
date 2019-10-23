

terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}



resource "aws_ecs_service" "service_with_elb" {
  depends_on = [aws_iam_role_policy.ecs_service_policy]

  name            = var.service_name
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.task.arn


  iam_role = aws_iam_role.ecs_service_role[0].arn

  desired_count                      = var.desired_number_of_tasks
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  ordered_placement_strategy {
    type  = var.placement_strategy_type
    field = var.placement_strategy_field
  }

  load_balancer {
    elb_name       = var.elb_name
    container_name = var.elb_container_name
    container_port = var.elb_container_port
  }

  placement_constraints {
    type       = var.placement_constraint_type
    expression = var.placement_constraint_expression
  }
}






# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM ROLE FOR THE SERVICE
# We output the id of this IAM role in case the module user wants to attach custom IAM policies to it. Note that the
# role is only created and used if this ECS Service is being used with an ELB.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_service_role" {
  count = var.is_associated_with_elb ? 1 : 0

  name               = "${var.service_name}-${var.environment_name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role.json

  # IAM objects take time to propagate. This leads to subtle eventual consistency bugs where the ECS service cannot be
  # created because the IAM role does not exist. We add a 15 second wait here to give the IAM role a chance to propagate
  # within AWS.
  provisioner "local-exec" {
    command = "echo 'Sleeping for 15 seconds to wait for IAM role to be created'; sleep 15"
  }
}

data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM POLICY THAT ALLOWS THE SERVICE TO TALK TO THE ELB
# Note that this policy is only created and used if this ECS Service is being used with an ELB.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "ecs_service_policy" {
  count = var.is_associated_with_elb ? 1 : 0

  name   = "${var.service_name}-ecs-service-policy"
  role   = aws_iam_role.ecs_service_role[0].id
  policy = data.aws_iam_policy_document.ecs_service_policy.json

  # IAM objects take time to propagate. This leads to subtle eventual consistency bugs where the ECS task cannot be
  # created because the IAM role does not exist. We add a 15 second wait here to give the IAM role a chance to propagate
  # within AWS.
  provisioner "local-exec" {
    command = "echo 'Sleeping for 15 seconds to wait for IAM role to be created'; sleep 15"
  }
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect = "Allow"

    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
    ]

    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM ROLE FOR AUTO SCALING THE ECS SERVICE
# For details, see: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/autoscale_IAM_role.html
# ---------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ECS TASK DEFINITION
# ---------------------------------------------------------------------------------------------------------------------

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



# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ECS TASK IAM ROLE
# Per https://goo.gl/xKpEOp, the ECS Task IAM Role is where arbitrary IAM Policies (permissions) will be attached to
# support the unique needs of the particular ECS Service being created. Because the necessary IAM Policies depend on the
# particular ECS Service, we create the IAM Role here, but the permissions will be attached in the Terraform template
# that consumes this module.
# ---------------------------------------------------------------------------------------------------------------------

# Create the ECS Task IAM Role
resource "aws_iam_role" "ecs_task" {
  name               = "${var.service_name}-${var.environment_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json

  # IAM objects take time to propagate. This leads to subtle eventual consistency bugs where the ECS task cannot be
  # created because the IAM role does not exist. We add a 15 second wait here to give the IAM role a chance to propagate
  # within AWS.
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

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM POLICY AND EXECUTION ROLE TO ALLOW ECS TASK TO MAKE CLOUDWATCH REQUESTS AND PULL IMAGES FROM ECR
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.task_execution_name_prefix}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json

  # IAM objects take time to propagate. This leads to subtle eventual consistency bugs where the ECS task cannot be
  # created because the IAM role does not exist. We add a 15 second wait here to give the IAM role a chance to propagate
  # within AWS.
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

locals {
  task_execution_name_prefix = var.custom_task_execution_name_prefix != "" ? var.custom_task_execution_name_prefix : var.service_name
}

# ---------------------------------------------------------------------------------------------------------------------
# CHECK THE ECS SERVICE DEPLOYMENT
# ---------------------------------------------------------------------------------------------------------------------

data "aws_arn" "ecs_service" {
  arn = local.ecs_service_arn
}

locals {
  ecs_service_arn = element(
    concat(
      aws_ecs_service.service_with_elb_without_auto_scaling.*.id,
      aws_ecs_service.service_with_elb_with_auto_scaling.*.id,
      aws_ecs_service.service_without_elb_without_auto_scaling.*.id,
      aws_ecs_service.service_without_elb_with_auto_scaling.*.id,
    ),
    0,
  )

  ecs_service_task_definition_arn = element(
    concat(
      aws_ecs_service.service_with_elb_without_auto_scaling.*.task_definition,
      aws_ecs_service.service_with_elb_with_auto_scaling.*.task_definition,
      aws_ecs_service.service_without_elb_without_auto_scaling.*.task_definition,
      aws_ecs_service.service_without_elb_with_auto_scaling.*.task_definition,
    ),
    0,
  )

  ecs_service_desired_count = element(
    concat(
      aws_ecs_service.service_with_elb_without_auto_scaling.*.desired_count,
      aws_ecs_service.service_with_elb_with_auto_scaling.*.desired_count,
      aws_ecs_service.service_without_elb_without_auto_scaling.*.desired_count,
      aws_ecs_service.service_without_elb_with_auto_scaling.*.desired_count,
    ),
    0,
  )

}
