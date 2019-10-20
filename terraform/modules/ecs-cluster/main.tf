terraform {
  required_version = ">= 0.12"
}

resource "aws_ecs_cluster" "ecs" {
  name = var.cluster_name
}

resource "aws_autoscaling_group" "ecs" {
  name                 = var.cluster_name
  min_size             = var.min_size
  max_size             = var.max_size
  launch_configuration = aws_launch_configuration.ecs.name
  vpc_zone_identifier  = var.vpc_subnet_ids
  termination_policies = var.termination_policies
  tags                 = concat(local.default_tags, var.custom_tags_ec2_instances)
}

resource "aws_launch_configuration" "ecs" {
  depends_on = [aws_ecs_cluster.ecs]

  name_prefix          = "${var.cluster_name}-"
  image_id             = var.cluster_instance_ami
  instance_type        = var.cluster_instance_type
  key_name             = var.cluster_instance_keypair_name
  security_groups      = [aws_security_group.ecs.id]
  user_data            = var.cluster_instance_user_data
  iam_instance_profile = aws_iam_instance_profile.ecs.name
  placement_tenancy    = var.cluster_instance_spot_price == null ? var.tenancy : null
  spot_price           = var.cluster_instance_spot_price

  root_block_device {
    volume_size = var.cluster_instance_root_volume_size
    volume_type = var.cluster_instance_root_volume_type
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  default_tags = [
    {
      key                 = "Name"
      value               = var.cluster_name
      propagate_at_launch = true
    },
  ]
}

resource "aws_security_group" "ecs" {
  name        = var.cluster_name
  description = "For EC2 Instances in the ${var.cluster_name} ECS Cluster."
  vpc_id      = var.vpc_id
  tags        = var.custom_tags_security_group

  # For an explanation of why this is here, see the aws_launch_configuration.ecs
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_outbound_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "allow_inbound_ssh_from_security_group" {
  count = var.allow_ssh ? 1 : 0

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.allow_ssh_from_security_group_id
  security_group_id        = aws_security_group.ecs.id
}


resource "aws_security_group_rule" "allow_inbound_from_alb" {

  count = var.num_alb_security_group_ids

  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = element(var.alb_security_group_ids, count.index)
  security_group_id        = aws_security_group.ecs.id
}

resource "aws_iam_role" "ecs" {
  name               = "${var.cluster_name}-instance"
  assume_role_policy = data.aws_iam_policy_document.ecs_role.json


  lifecycle {
    create_before_destroy = true
  }


  provisioner "local-exec" {
    command = "echo 'Sleeping for 15 seconds to wait for IAM role to be created'; sleep 15"
  }
}
