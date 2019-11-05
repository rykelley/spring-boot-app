
variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default = "us-east-1"
}

variable "aws_account_id" {
  description = "A comma-separated list of AWS Account IDs. Only these IDs may be operated on by this template."
  type        = string
  default = "522052662196"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default = "spring-boot-app"
}

variable "ecs_cluster_instance_ami" {
  description = "The AMI to run on each instance in the ECS cluster"
  type        = string
  default = "ami-00dc79254d0461090"
}

variable "ecs_cluster_instance_type" {
  description = "The type of instances to run in the ECS cluster (e.g. t2.micro)"
  type        = string
  default     = "t2.micro"
}

variable "ecs_cluster_instance_keypair_name" {
  description = "The name of the Key Pair that can be used to SSH to each instance in the ECS cluster"
  type        = string
  default = "spring-app"
}

variable "ecs_cluster_vpc_subnet_ids" {
  description = "A list of subnet ids in which the ECS cluster should be deployed."
  type        = list(string)
  default = ["subnet-013955a7437af7185", "subnet-0cc5981e3a627bb68", "subnet-0d5ce920b881f1ea7",]
}

variable "vpc_id" {
  description = "The id of the VPC in which to run the ECS cluster"
  type        = string
  default = "vpc-09d98e84363d15df3"
}

variable "container_name" {
  description = "The name of the container in the ECS Task Definition. This is only useful if you have multiple containers defined in the ECS Task Definition. Otherwise, it doesn't matter."
  type        = string
  default     = "spring-boot-app"
}

variable "service_name" {
  description = "The name of the ECS service to run"
  type        = string
  default     = "ecs-alb-spring-boot"
}

variable "environment_name" {
  description = "The environment name in which the ALB is located. (e.g. prod)"
  type        = string
  default = "prod"
}

variable "container_http_port" {
  description = "The port var.docker_image listens on for HTTP requests"
  type        = number

  # The Docker container we run in this example listens on port 3000
  default = 3000
}

variable "server_text" {
  description = "The Docker container we run in this example will display this text for every request."
  type        = string
  default     = "Hello testing"
}

variable "s3_test_file_name" {
  description = "The name of the file to store in the S3 bucket. The ECS Task will try to download this file from S3 as a way to check that we are giving the Task the proper IAM permissions."
  type        = string
  default     = "s3-test-file.txt"
}

variable "alb_vpc_subnet_ids" {
  description = "A list of the subnets into which the ALB will place its underlying nodes. Include one subnet per Availabability Zone. If the ALB is public-facing, these should be public subnets. Otherwise, they should be private subnets."
  type        = list(string)
  default = ["subnet-07e5e8c349989d8c0", "subnet-07eb56ed7c079a808", "subnet-07eb56ed7c079a808",]

}


variable "desired_number_of_tasks" {
  description = "How many copies of the task to run across the cluster"
  type        = number
  default     = 2
}

variable "min_number_of_tasks" {
  description = "Minimum number of copies of the task to run across the cluster"
  type        = number
  default     = 2
}

variable "max_number_of_tasks" {
  description = "Maximum number of copies of the task to run across the cluster"
  type        = number
  default     = 2
}

variable "container_memory" {
  description = "Amount of memory to provision for the container"
  type        = number
  default     = 256
}

variable "skip_s3_test_file_creation" {
  description = "Whether or not to skip s3 test file creation. Set this to true to see what happens when the container is set up to crash."
  type        = bool
  default     = false
}

variable "enable_ecs_deployment_check" {
  description = "Whether or not to enable ECS deployment check. This requires installation of the check-ecs-service-deployment binary. See the ecs-deploy-check-binaries module README for more information."
  type        = bool
  default     = false
}

variable "deployment_check_timeout_seconds" {
  description = "Number of seconds to wait for the ECS deployment check before giving up as a failure."
  type        = number
  default     = 600
}

variable "container_command" {
  description = "Command to run on the container. Set this to see what happens when a container is set up to exit on boot."
  type        = list(string)
  default     = []
  # Example:
  # default = ["echo", "Hello"]
}

variable "container_boot_delay_seconds" {
  description = "Delay the boot up sequence of the container by this many seconds. Use this to test various booting scenarios (e.g crash container after a long boot) against the deployment check."
  type        = number
  default     = 0
}

variable "health_check_grace_period_seconds" {
  description = "How long to wait before having the ALB start checking health."
  type        = number
  # By default, give the container 15 seconds to boot
  default = 15
}