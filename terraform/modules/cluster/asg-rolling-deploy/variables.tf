
variable "cluster_name" {
  description = "the name of the cluster"
  type        = string
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "image_id" {
  description = "Name of our AMI ID"
  type        = string
}

variable "instance_type" {
  description = "Size and type of instance"
  type        = string
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "custom_tags" {
  description = "Custom tags to set on the instances in the asg"
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  description = "if set to true then autoscale by schedule"
  type        = bool
}

variable "subnet_ids" {
  description = "the subnet ID's to deploy"
  type        = string
}

variable "target_group_arn" {
  description = "the ARN's of ELB target groups in which to register Instacnes"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "the type of health check to perform must be either EC2 or ELB"
  type        = StringLike
  default     = "EC2"
}

variable "user_data" {
  description = "user data to run "
  type        = "string"
  default     = ""
}
