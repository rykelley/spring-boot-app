
terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN EC2 INSTANCE
# We are using the single-server module to create this instance, as it takes care of the common details like IAM
# Roles, Security Groups, etc.
# ---------------------------------------------------------------------------------------------------------------------

module "example" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-server.git//modules/single-server?ref=v0.0.40"
  source = "../../modules/single-server"

  name          = var.name
  instance_type = var.instance_type
  ami           = var.ami


  # To make this example easy to test, we allow SSH access from any IP. In real-world usage, you should only allow SSH
  # access from known, trusted servers (e.g., a bastion host).
  allow_ssh_from_cidr_list = ["0.0.0.0/0"]

  keypair_name = var.keypair_name

  # To keep this example easy to try, we run it in the default VPC and subnet. In real-world usage, you should
  # typically create a custom VPC and run your code in private subnets.
  vpc_id = data.aws_vpc.default.id

  subnet_id = data.aws_subnet.selected.id

  # The user data script will attach the volume
  user_data = data.template_file.user_data.rendered
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE EBS VOLUMES
# If you have an EBS Volume Snapshot from which the new EBS Volume should be created, just add a snapshot_id parameter.
# ---------------------------------------------------------------------------------------------------------------------

# We will attach this volume by ID
resource "aws_ebs_volume" "example_1" {
  availability_zone = data.aws_subnet.selected.availability_zone
  type              = "gp2"
  size              = 5
}

# We will attach this volume by Name tag
resource "aws_ebs_volume" "example_2" {
  availability_zone = data.aws_subnet.selected.availability_zone
  type              = "gp2"
  size              = 5

  tags = {
    Name = var.name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE USER DATA SCRIPT TO RUN ON THE INSTANCE WHEN IT BOOTS
# This script will attach and mount the EBS volume
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    aws_region    = var.aws_region
    volume_1_id   = aws_ebs_volume.example_1.id
    device_1_name = var.device_1_name
    mount_1_point = var.mount_1_point
    volume_2_tag  = "Name"
    device_2_name = var.device_2_name
    mount_2_point = var.mount_2_point
    owner         = var.user
    name          = var.name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM POLICY THAT ALLOWS THE INSTANCE TO ATTACH VOLUMES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "manage_ebs_volume" {
  name   = "manage-ebs-volume"
  role   = module.example.iam_role_id
  policy = data.aws_iam_policy_document.manage_ebs_volume.json
}

data "aws_iam_policy_document" "manage_ebs_volume" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/${aws_ebs_volume.example_1.id}",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/${aws_ebs_volume.example_2.id}",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${module.example.id}",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeVolumes", "ec2:DescribeTags"]
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THIS EXAMPLE IN THE DEFAULT VPC AND SUBNETS
# To keep this example simple, we deploy it in the default VPC and subnets. In real-world usage, you'll probably want
# to use a custom VPC and private subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_subnet" "selected" {
  id = element(tolist(data.aws_subnet_ids.default.ids), 0)
}

data "aws_caller_identity" "current" {}
