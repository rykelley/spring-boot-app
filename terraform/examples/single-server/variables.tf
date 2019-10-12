# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be passed in by the templates using this module.
# ----------------------------------------------------------------------------------------------------------------------

variable "ami" {
  description = "The ID of an AMI to run on the EC2 instance. It should have mount-ebs-volume and the AWS CLI installed. See packer/build.json."
  type        = string
  default     = "ami-0d5d9d301c853a04a"
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables may be optionally passed in by the templates using this module to overwite the defaults.
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-east-2"
}

variable "name" {
  description = "The name used to namespace all resources created by these templates."
  type        = string
  default     = "single-server"
}

variable "instance_type" {
  description = "The instance type (e.g t2.micro) to use when creating the EC2 instance."
  type        = string
  default     = "t2.micro"
}

variable "keypair_name" {
  description = "The name of the Key Pair that can be used to SSH to this EC2 instance. Leave blank if you don't want to use a Key Pair."
  type        = string
  default     = "spring-app"
}

variable "user" {
  description = "The OS user who should own the EBS Volume mount points. If you use the Ubuntu AMI, this should be ubuntu. If you use the CentOS AMI, this should be CentOS."
  type        = string
  default     = "ubuntu"
}

variable "device_1_name" {
  description = "The device name to use for the first EBS volume"
  type        = string
  default     = "/dev/xvdh"
}

variable "mount_1_point" {
  description = "The mount point to use for the first EBS volume"
  type        = string
  default     = "/data_1"
}

variable "device_2_name" {
  description = "The device name to use for the second EBS volume"
  type        = string
  default     = "/dev/xvdi"
}

variable "mount_2_point" {
  description = "The mount point to use for the second EBS volume"
  type        = string
  default     = "/data_2"
}
