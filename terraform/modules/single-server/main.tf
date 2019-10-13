
terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

resource "aws_instance" "instance" {
  ami                    = var.ami
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.instance.name
  key_name               = var.keypair_name
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id              = var.subnet_id
  user_data              = var.user_data
  tenancy                = var.tenancy
  source_dest_check      = var.source_dest_check


  tags = merge(
    { "Name" = var.name },
    var.tags,
  )

  ebs_optimized = var.ebs_optimized

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.root_volume_delete_on_termination
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM ROLE
# This module doesn't know what permissions the user will want, but we can only assign an IAM Role when launching an
# EC2 instance (not after) so we define an empty IAM Role and export its id so users can attach their custom policies
# later.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "instance" {
  name               = data.template_file.iam_role_name.rendered
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  # Workaround for a bug where Terraform sometimes doesn't wait long enough for the IAM role to propagate.
  # https://github.com/hashicorp/terraform/issues/2660
  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds to work around IAM Instance Profile propagation bug in Terraform' && sleep 30"
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# To assign an IAM Role to an EC2 instance, we actually need to assign the "IAM Instance Profile"
resource "aws_iam_instance_profile" "instance" {
  name = data.template_file.iam_role_name.rendered
  role = aws_iam_role.instance.name

  # Workaround for a bug where Terraform sometimes doesn't wait long enough for the IAM instance profile to propagate.
  # https://github.com/hashicorp/terraform/issues/4306
  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds to work around IAM Instance Profile propagation bug in Terraform' && sleep 30"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO CONTROL TRAFFIC IN AND OUT OF THE SERVER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "instance" {
  name_prefix            = data.template_file.security_group_name.rendered
  description            = "Security Group for ${data.template_file.security_group_name.rendered}"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_security_group_rules_on_delete

  # We want to set the name of the resource with var.name, but all other tags should be settable with var.tags.
  tags = merge(
    {
      "Name" = data.template_file.security_group_name.rendered
    },
    var.tags,
  )

  lifecycle {
    # This Security Group will be deleted and recreated if the user changes its name. However, aws_instance.instance
    # depends on this Security Group, so if we try to delete it, we'll get a "DependencyViolation: resource sg-XXX has
    # a dependent object" error. Therefore, we need to create the new security group first, which will update
    # aws_instance.instance, and then we can delete the old one. For more info, see:
    # https://github.com/terraform-providers/terraform-provider-aws/issues/1671
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_outbound_all" {
  count             = var.allow_all_outbound_traffic ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance.id
}
# would not normally do this but i ran out of time. 
resource "aws_security_group_rule" "allow_inbound_ssh_from_cidr" {
  count             = var.allow_ssh_from_cidr ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allow_ssh_from_cidr_list
  security_group_id = aws_security_group.instance.id
}

resource "aws_security_group_rule" "allow_inbound_app" {
  type              = "ingress"
  from_port         = 8081
  to_port           = 8081
  protocol          = "tcp"
  cidr_blocks       = var.allow_ssh_from_cidr_list
  security_group_id = aws_security_group.instance.id
}



resource "aws_security_group_rule" "allow_inbound_ssh_from_security_group" {
  count                    = var.allow_ssh_from_security_group ? 1 : 0
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.allow_ssh_from_security_group_id
  security_group_id        = aws_security_group.instance.id
}

# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "security_group_name" {
  template = var.security_group_name == "" ? var.name : var.security_group_name
}

data "template_file" "iam_role_name" {
  template = var.iam_role_name == "" ? var.name : var.iam_role_name
}
