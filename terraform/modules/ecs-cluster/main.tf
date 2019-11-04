terraform {
    required_version = ">= 0.12"
}

resource "aws_ecs_cluster" "ecs" {
    name = var.cluster_name
}


resource "aws_autoscaling_group" "ecs-asg" {
    depends_on = [aws_ecs_cluster.ecs]

    name = var.cluster_name
    min_size = var.cluster_min_size
    max_size = var.cluster_max_size
    launch_configuration = aws_launch_configuration.ecs.name
    vpc_zone_identifier = var.vpc_subnet_ids
    termination_policies = var.termination_policies
    tags = concat(local.default_tags, var.custom_tags_ec2_instances)
}

resource "aws_launch_configuration" "ecs" {
    depends_on = [aws_ecs_cluster.ecs]
  
    name_prefix = "${var.cluster_name}-"
    image_id = var.cluster_instance_ami
    instance_type = var.cluster_instance_type
    key_name = var.cluster_instance_keypair
    security_groups = [aws_security_group.ecs.id]
    user_data = var.cluster_user_data
    iam_instance_profile = aws_iam_instance.ecs.name

    root_block_device {
        volume_size = var.root_volume_size
        volume_type = var.root_volume_type
    }
    lifecycle {
        create_before_destroy = true
    }

}


locals {
    default_tags = [
        {
            key = "name"
            value = var.cluster_name
            propagate_at_launch = true
        
        },
    ]
}

resource "aws_security_group" "ecs" {
    name = var.cluster_name
    description = "for cluster instances in the ${var.cluster_name} ECS Cluster"
    vpc_id = var.vpc_id
    tags = var.custom_tags_security_group

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group_rule" "outbound_all" {
    type = egress
    from_port = 0
    to_port = 0 
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "inbound_ssh_from_security_group" {
    count = var.allow_ssh ? 1 : 0

    type = ingress
    from_port = 22
    to_port = 22 
    protocol = "tcp"
    source_security_group_id = var.allow_ssh
    security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_id" "inbound_from_alb" {
    count = var.num_alb_security_group_ids

    type = "ingress"
    from_port = 32768
    to_port = 65535
    protocol = "tcp"
    source_security_group_id = element(var.alb_security_group_ids, count.index)
    security_group_id = aws_security_group.ecs.id
  
}

resource "aws_iam_role" "ecs" {
    name = "${var.cluster_name}-instance"
    assume_role_policy = data.aws_iam_policy_document.ecs_role.json
  
  lifecycle {
      create_before_destroy = true
  }

provisioner "local-exec" {
    command = "echo 'sleeping for 15 seconds'; sleep 15"
  }
}


data "aws_iam_policy" "ecs_role" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_instance_profile" "ecs" {
    name = var.cluster_name
    role = aws_iam_role.ecs.name

    lifecycle {
        create_before_destroy = true
    }
  
}
resource "aws_iam_role_policy" "ecs" {
    name = "${var.cluster_name}-ecs-permissions"
    role = aws_iam_role.ecs.id
    policy = data.aws_iam_policy_document.ecs_permissions.json
}

data "aws_iam_policy_document" "ecs_permissions" {
    statement {
        effect = "allow"

        actions = [
            "ecs:CreateCluster",
            "ecs:DiscoverPollEndpoint",
            "ecs:DeregisterContainerInstance",
            "ecs:Poll",
            "ecs:RegisterContainerInstance",
            "ecs:StartTelemetrySession",
            "ecs:Submit*",
        ]
        resources = ["*"]

    }
}

resource "aws_iam_role_policy" "ecr" {
    name = "${var.cluster_name}-docker-login-for-ecr"
    role = aws_iam_role.ecs.id
    policy = data.aws_iam_policy_document.ecr_permissions.json
  }

data "aws_iam_policy_document" "ecr_permissions" {
statement {
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
    ]

    resources = ["*"]
  }
}



