

variable "aws_account_id" {
  description = "The AWS Account ID in which the ALB and its S3 Bucket will be created."
  type        = string
}

variable "aws_region" {
  description = "The AWS region in which the ALB and its corresponding S3 Bucket used for logging will be created."
  type        = string
}

variable "alb_name" {
  description = "The name of the ALB. Do not include the environment name since this module will automatically append it to the value of this variable."
  type        = string
}

variable "environment_name" {
  description = "The environment name in which the ALB is located. (e.g. stage, prod)"
  type        = string
}

variable "is_internal_alb" {
  description = "If the ALB should only accept traffic from within the VPC, set this to true. If it should accept traffic from the public Internet, set it to false."
  type        = bool
}

variable "additional_security_group_ids" {
  description = "Add additional security groups to the ALB"
  type        = list(string)
  default     = []
}



# Info about the VPC in which this Cluster resides
variable "vpc_id" {
  description = "The VPC ID in which this ALB will be placed."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "A list of the subnets into which the ALB will place its underlying nodes. Include one subnet per Availabability Zone. If the ALB is public-facing, these should be public subnets. Otherwise, they should be private subnets."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "http_listener_ports" {
  description = "A list of ports for which an HTTP Listener should be created on the ALB. Tip: When you define Listener Rules for these Listeners, be sure that, for each Listener, at least one Listener Rule uses the '*' path to ensure that every possible request path for that Listener is handled by a Listener Rule. Otherwise some requests won't route to any Target Group."
  type        = list(string)
  default     = []
}



variable "allow_all_outbound" {
  description = "Set to true to enable all outbound traffic on this ALB. If set to false, the ALB will allow no outbound traffic by default. This will make the ALB unusuable, so some other code must then update the ALB Security Group to enable outbound access!"
  type        = bool
  default     = true
}

variable "enable_alb_access_logs" {
  description = "Set to true to enable the ALB to log all requests. Ideally, this variable wouldn't be necessary, but because Terraform can't interpolate dynamic variables in counts, we must explicitly include this. Enter true or false."
  type        = bool
  default     = false
}

variable "alb_access_logs_s3_bucket_name" {
  description = "The S3 Bucket name where ALB logs should be stored. If left empty, no ALB logs will be captured. Tip: It's easiest to create the S3 Bucket using the Gruntwork Module https://github.com/gruntwork-io/module-aws-monitoring/tree/master/modules/logs/load-balancer-access-logs."
  type        = string
  default     = null
}

variable "allow_inbound_from_cidr_blocks" {
  description = "The CIDR-formatted IP Address ranges from which this ALB will allow incoming requests. If var.is_internal_alb is false, use the default value. If var.is_internal_alb is true, consider setting this to the VPC's CIDR Block, or something even more restrictive."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_inbound_from_security_group_ids" {
  description = "The IDs of security groups from which this ALB will allow incoming requests. . If you update this variable, make sure to update var.allow_inbound_from_security_group_ids_num too!"
  type        = list(string)
  default     = []
}

variable "allow_inbound_from_security_group_ids_num" {
  description = "The number of elements in var.allow_inbound_from_security_group_ids. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_security_group_ids, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "idle_timeout" {
  description = "The time in seconds that the client TCP connection to the ALB is allowed to be idle before the ALB closes the TCP connection.  "
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the ALB will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer."
  type        = bool
  default     = false
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the ALB and its Security Group. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "default_action_content_type" {
  description = "If a request to the load balancer does not match any of your listener rules, the default action will return a fixed response with this content type."
  type        = string
  default     = "text/plain"
}

variable "default_action_body" {
  description = "If a request to the load balancer does not match any of your listener rules, the default action will return a fixed response with this body."
  type        = string
  default     = null
}

variable "default_action_status_code" {
  description = "If a request to the load balancer does not match any of your listener rules, the default action will return a fixed response with this status code."
  type        = number
  default     = 404
}
