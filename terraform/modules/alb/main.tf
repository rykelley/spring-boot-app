

terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}




resource "aws_alb" "alb_with_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  name     = var.alb_name
  internal = var.is_internal_alb
  security_groups = concat(
    [aws_security_group.alb.id],
    var.additional_security_group_ids,
  )

  subnets      = var.vpc_subnet_ids
  idle_timeout = var.idle_timeout

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(
    {
      "Environment" = var.environment_name
    },
    var.custom_tags,
  )

  access_logs {
    bucket  = var.alb_access_logs_s3_bucket_name
    prefix  = var.alb_name
    enabled = true
  }
}




# Create one HTTP Listener for each given HTTP port.
resource "aws_alb_listener" "http" {
  count = length(var.http_listener_ports)

  load_balancer_arn = local.alb_arn
  port              = element(var.http_listener_ports, count.index)
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response = {
      content_type = var.default_action_content_type
      message_body = var.default_action_body
      status_code  = var.default_action_status_code
    }
  }
}




# Create a Security Group for the ALB itself.
resource "aws_security_group" "alb" {
  name        = "${var.alb_name}-alb"
  description = "For the ${var.alb_name}-alb ALB."
  vpc_id      = var.vpc_id
  tags = merge(
    {
      "Environment" = var.environment_name
    },
    var.custom_tags,
  )
}

# Create one inbound security group rule for each HTTP Listener Port that allows access from the CIDR blocks in var.allow_inbound_from_cidr_blocks.
resource "aws_security_group_rule" "http_listeners" {
  count = length(var.http_listener_ports) * signum(length(var.allow_inbound_from_cidr_blocks))

  type = "ingress"
  from_port = element(
    data.template_file.http_listener_ports_keys_non_empty.*.rendered,
    count.index,
  )
  to_port = element(
    data.template_file.http_listener_ports_keys_non_empty.*.rendered,
    count.index,
  )
  protocol = "tcp"

  cidr_blocks       = var.allow_inbound_from_cidr_blocks
  security_group_id = aws_security_group.alb.id
}

# Create one inbound security group rule for each HTTP Listener Port that allows access from each security group in var.allow_inbound_from_security_group_ids.
resource "aws_security_group_rule" "http_listeners_for_security_groups" {
  count = length(var.http_listener_ports) * var.allow_inbound_from_security_group_ids_num

  type = "ingress"
  from_port = element(
    data.template_file.http_listener_ports_keys_non_empty.*.rendered,
    floor(count.index / var.allow_inbound_from_security_group_ids_num),
  )
  to_port = element(
    data.template_file.http_listener_ports_keys_non_empty.*.rendered,
    floor(count.index / var.allow_inbound_from_security_group_ids_num),
  )
  protocol = "tcp"

  source_security_group_id = element(
    data.template_file.allow_inbound_from_security_group_ids_non_empty.*.rendered,
    count.index % var.allow_inbound_from_security_group_ids_num,
  )
  security_group_id = aws_security_group.alb.id
}


locals {
  alb_arn = var.enable_alb_access_logs ? aws_alb.alb_with_logs[0].arn : aws_alb.alb_without_logs[0].arn
}

# OK, this is a horribly hacky workaround that contains another horribly hack workaround due to two nasty Terraform
# limitations:
#
# 1. If you call element(...) on an empty list, you get an error. This is a problem because, even if you call
#    element(...) on an empty list inside of a resource with count set to 0 (that is, a resource that should not be
#    created at all!), the element(...) interpolation still gets processed, because Terraform does not do lazy
#    evaluation. See: https://github.com/hashicorp/terraform/issues/11210.
#
# 2. Terraform does not allow lists to be used with conditional syntax. Therefore, we have to call join(...) on the
#    lists to convert them into strings and then call split(...) to turn them back into lists. See:
#    https://github.com/hashicorp/terraform/issues/12453.
#
# After going through this whole process, we end up with a list of template_file data sources that are guaranteed to
# be non-empty. If the underlying var.http_listener_xxx for each template_file is non-empty, that template_file will
# contain all the keys in that variable. If the variable is empty, it will contain a single placeholder value, which
# allows us to avoid the error from calling element(...) on an empty list.
#
data "template_file" "http_listener_ports_keys_non_empty" {
  count = length(var.http_listener_ports) > 0 ? length(var.http_listener_ports) : 1
  template = element(
    split(
      ",",
      length(var.http_listener_ports) > 0 ? join(",", var.http_listener_ports) : "placeholder",
    ),
    count.index,
  )
}



# In certain cases, the count param on the aws_security_group_rule resources we have above cannot be computed early
# (e.g., when a data source + math is used in it), so it tries to process the fields of that resource, even though
# count will eventually turn out to be 0. In those cases, if var.allow_inbound_from_security_group_ids is empty, and
# we call element() on it, we'll get an error. This is a hacky workaround to create a list that is guaranteed to be
# non-empty so we can safely call element() on it.
data "template_file" "allow_inbound_from_security_group_ids_non_empty" {
  count = max(var.allow_inbound_from_security_group_ids_num, 1)
  template = element(
    split(
      ",",
      var.allow_inbound_from_security_group_ids_num > 0 ? join(",", var.allow_inbound_from_security_group_ids) : "placeholder",
    ),
    count.index,
  )
}
