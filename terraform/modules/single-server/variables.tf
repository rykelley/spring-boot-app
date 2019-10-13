# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be passed in by the templates using this module.
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the server. This will be used to namespace all resources created by this module."
  type        = string
}

variable "ami" {
  description = "The ID of the AMI to run for this server."
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to run (e.g. t2.micro)"
  type        = string
}

variable "vpc_id" {
  description = "The id of the VPC where this server should be deployed."
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet where this server should be deployed."
  type        = string
}

variable "keypair_name" {
  description = "The name of a Key Pair that can be used to SSH to this instance. Leave blank if you don't want to enable Key Pair auth."
  type        = string
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables may be optionally passed in by the templates using this module to overwite the defaults.
# ----------------------------------------------------------------------------------------------------------------------

variable "user_data" {
  description = "The User Data script to run on this instance when it is booting."
  type        = string
  default     = null
}

variable "allow_ssh_from_cidr" {
  description = "A boolean that specifies if this server will allow SSH connections from the list of CIDR blocks specified in var.allow_ssh_from_cidr_list."
  type        = bool
  default     = true
}
#bad practice here. Don't do this. 
variable "allow_ssh_from_cidr_list" {
  description = "A list of IP address ranges in CIDR format from which SSH access will be permitted. Attempts to access the bastion host from all other IP addresses will be blocked. This is only used if var.allow_ssh_from_cidr is true."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_ssh_from_security_group" {
  description = "A boolean that specifies if this server will allow SSH connections from the security group specified in var.allow_ssh_from_security_group_id."
  type        = bool
  default     = false
}

variable "allow_ssh_from_security_group_id" {
  description = "The ID of a security group from which SSH connections will be allowed. Only used if var.allow_ssh_from_security_group is true."
  type        = string
  default     = null
}

variable "allow_all_outbound_traffic" {
  description = "A boolean that specifies whether or not to add a security group rule that allows all outbound traffic from this server."
  type        = bool
  default     = true
}


variable "tenancy" {
  description = "The tenancy of this server. Must be one of: default, dedicated, or host."
  type        = string
  default     = "default"
}

variable "source_dest_check" {
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance. Must be set to a boolean (not a string!) true or false value."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A set of tags to set for the EC2 Instance and Security Group. Note that other AWS resources created by this module such as an Elastic IP Address and Route53 Record do not support tags."
  type        = map(string)
  default     = {}
}

variable "ebs_optimized" {
  description = "If true, the launced EC2 Instance will be EBS-optimized."
  type        = bool
  default     = false
}

variable "root_volume_type" {
  description = "The root volume type. Must be one of: standard, gp2, io1."
  type        = string
  default     = "standard"
}

variable "root_volume_size" {
  description = "The size of the root volume, in gigabytes."
  type        = number
  default     = 8
}

variable "root_volume_delete_on_termination" {
  description = "If set to true, the root volume will be deleted when the Instance is terminated."
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "The name for the bastion host's security group. If set to an empty string, will use var.name."
  type        = string
  default     = ""
}

variable "iam_role_name" {
  description = "The name for the bastion host's IAM role and instance profile. If set to an empty string, will use var.name."
  type        = string
  default     = ""
}

variable "revoke_security_group_rules_on_delete" {
  description = "Instruct Terraform to revoke all of the Security Groups attached ingress and egress rules before deleting the rule itself. This is normally not needed, however certain AWS services such as Elastic Map Reduce may automatically add required rules to security groups used with the service, and those rules may contain a cyclic dependency that prevent the security groups from being destroyed without removing the dependency first."
  type        = bool
  default     = false
}
