variable "cluster_name" {
  description = "The name of the ECS cluster"
  type = string 
}

variable "cluster_min_size" {
  description = "min number of EC2 instances"
  type = number
}

variable "cluster_max_size" {
  description = "the Max number of ECS instances"
  type = number
}

variable "cluster_instance_ami" {
  description = "the AMI "
  type = string
}

variable "cluster_instance_type" {
  description = "the Type of EC2 instance to run"
  type = string
}

variable "cluster_root_volume_size" {
  description = ""
  type = number
  default = 40
}

variable "cluster_root_volume_type" {
  description = "THe voume type for the root volume "
  type = string
  default = "default"
}

variable "cluster_instance_user_data" {
  description = ""
  type = string
  default = "null"
}

variable "cluster_instance_spot_price" {
  description = "description"
  type = string
  default = "null"
}

variable "vpc_id" {
  description = "description"
  type = spring
}

variable "vpc_subnet_ids" {
  description = "description"
  type = list(string)
}

variable "allow_ssh_from_security_group_id" {
  description = "description"
  type = string
}

variable "allow_ssh" {
  description = "Set to true if var.allow_ssh_from_security_group_id is non-empty; false, otherwise. 
  type        = bool
}

variable "alb_security_group_ids" {
  description = "A list of Security Group IDs of the ALBs which will send traffic to this ECS Cluster."
  type        = list(string)
  default     = []
}

variable "num_alb_security_group_ids" {
  description = "The number of entries in var.alb_arns. We should be able to infer this value from var.alb_arns, but due to a Terraform Bug (https://goo.gl/gq5Qyk), we must set it manually."
  type        = number
  default     = 0
}

variable "tenancy" {
  description = "The tenancy of the servers in this cluster. Must be one of: default, dedicated, or host."
  type        = string
  default     = "default"
}

variable "custom_tags_ec2_instances" {
  description = "A list of custom tags to apply to the EC2 Instances in this ASG. Each item in this list should be a map with the parameters key, value, and propagate_at_launch."
  type = list(
    object({
      key                 = string
      value               = string
      propagate_at_launch = bool
    })
  )
  default = []
  # Example:
  # default = [
  #   {
  #     key = "foo"
  #     value = "bar"
  #     propagate_at_launch = true
  #   },
  #   {
  #     key = "baz"
  #     value = "blah"
  #     propagate_at_launch = true
  #   }
  # ]
}

variable "custom_tags_security_group" {
  description = "A map of custom tags to apply to the Security Group for this ECS Cluster. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
  # Example:
  #   {
  #     key1 = "value1"
  #     key2 = "value2"
  #   }
}

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the auto scale group should be terminated. The allowed values are OldestInstance, NewestInstance, OldestLaunchConfiguration, ClosestToNextInstanceHour, OldestLaunchTemplate, AllocationStrategy, Default. If you specify more than one policy, the ASG will try each one in turn, use it to select the instance(s) to terminate, and if more than one instance matches the criteria, then use the next policy to try to break the tie. E.g., If you use ['OldestInstance', 'ClosestToNextInstanceHour'] and and there were two instances with exactly the same launch time, then the ASG would try the next policy, which is to terminate the one closest to the next instance hour in billing."
  type        = list(string)

  # Our default policy is optimized for rolling out updates to the ECS cluster via roll-out-ecs-cluster-update.py.
  # That script scales the cluster up to launch new instances and then back down with the intention of terminating
  # the older instances, so we need to use the OldestInstance policy for that to work.
  default = ["OldestInstance"]
}