
variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)"
  type        = string
}

variable "launch_configuration_name" {
  description = "The name of the Launch Configuration to use for each EC2 Instance in this ASG. This value MUST be an output of the Launch Configuration resource itself. This ensures a new ASG is created every time the Launch Configuration changes, rolling out your changes automatically."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "A list of subnet ids in the VPC were the EC2 Instances should be deployed"
  type        = list(string)
}

variable "min_size" {
  description = "The minimum number of EC2 Instances to run in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances to run in the ASG"
  type        = number
}

variable "desired_capacity" {
  description = "The desired number of EC2 Instances to run in the ASG initially. Note that auto scaling policies may change this value. If you're using auto scaling policies to dynamically resize the cluster, you should actually leave this value as null."
  type        = number
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the auto scale group should be terminated. The allowed values are OldestInstance, NewestInstance, OldestLaunchConfiguration, ClosestToNextInstanceHour, Default."
  type        = list(string)
  default     = []
}

variable "load_balancers" {
  description = "A list of Elastic Load Balancer (ELB) names to associate with this ASG. If you're using the Application Load Balancer (ALB), see var.target_group_arns."
  type        = list(string)
  default     = []
}

variable "target_group_arns" {
  description = "A list of Application Load Balancer (ALB) target group ARNs to associate with this ASG. If you're using the Elastic Load Balancer (ELB), see var.load_balancers."
  type        = list(string)
  default     = []
}

variable "min_elb_capacity" {
  description = "Wait for this number of EC2 Instances to show up healthy in the load balancer on creation."
  type        = number
  default     = 0
}

variable "health_check_grace_period" {
  description = "Time, in seconds, after an EC2 Instance comes into service before checking health."
  type        = number
  default     = 300
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for the EC2 Instances to be healthy before timing out."
  type        = string
  default     = "10m"
}

variable "availability_zones" {
  description = "A list of availability zones the ASG should use. The subnets in var.vpc_subnet_ids must reside in these Availability Zones."
  type        = list(string)
  default     = []
}

variable "enabled_metrics" {
  description = "A list of metrics the ASG should enable for monitoring all instances in a group. The allowed values are GroupMinSize, GroupMaxSize, GroupDesiredCapacity, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupTerminatingInstances, GroupTotalInstances."
  type        = list(string)
  default     = []

  # Example:
  # enabled_metrics = [
  #    "GroupDesiredCapacity",
  #    "GroupInServiceInstances",
  #    "GroupMaxSize",
  #    "GroupMinSize",
  #    "GroupPendingInstances",
  #    "GroupStandbyInstances",
  #    "GroupTerminatingInstances",
  #    "GroupTotalInstances"
  #  ]
}

variable "tag_asg_id_key" {
  description = "The key for the tag that will be used to associate a unique identifier with this ASG. This identifier will persist between redeploys of the ASG, even though the underlying ASG is being deleted and replaced with a different one."
  type        = string
  default     = "AsgId"
}

variable "custom_tags" {
  description = "A list of custom tags to apply to the EC2 Instances in this ASG. Each item in this list should be a map with the parameters key, value, and propagate_at_launch."
  type = list(object({
    key                 = string
    value               = string
    propagate_at_launch = bool
  }))
  default = [
    {
      key                 = "Name"
      value               = "spring-boot-instances"
      propagate_at_launch = true
    }
  ]

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
