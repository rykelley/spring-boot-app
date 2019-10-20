variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "The name of the VPC (e.g. stage, prod)"
  type        = string
  default     = "vpc-app-prod"
}
