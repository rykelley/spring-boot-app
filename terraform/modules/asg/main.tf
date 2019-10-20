

terraform {
  required_version = ">= 0.12"
}


resource "aws_autoscaling_group" "autoscaling_group" {

  name = var.launch_configuration_name

  launch_configuration = var.launch_configuration_name

  termination_policies = var.termination_policies

  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = data.external.get_desired_capacity.result["desired_capacity"]
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  min_elb_capacity          = var.min_elb_capacity

  load_balancers    = var.load_balancers
  target_group_arns = var.target_group_arns
  health_check_type = length(var.load_balancers) > 0 || length(var.target_group_arns) > 0 ? "ELB" : "EC2"

  vpc_zone_identifier       = var.vpc_subnet_ids
  availability_zones        = var.availability_zones
  health_check_grace_period = var.health_check_grace_period

  enabled_metrics = var.enabled_metrics

  tags = concat(local.default_tags, var.custom_tags)

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  default_tags = [
    {
      key                 = "Name"
      value               = var.launch_configuration_name
      propagate_at_launch = true
    },
    {

      key                 = var.tag_asg_id_key
      value               = random_id.asg_id.dec
      propagate_at_launch = true
    },
  ]
}


resource "random_id" "asg_id" {
  byte_length = 8
}
