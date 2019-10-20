variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-=east-1"
}

variable "aws_account_id" {
  description = "A comma-separated list of AWS Account IDs. Only these IDs may be operated on by this template."
  type        = string
  default     = "522052662196"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "spring-boot-cluster"
}

variable "ecs_cluster_instance_ami" {
  description = "The AMI to run on each instance in the ECS cluster"
  type        = string
  default     = "ami-0f846c06eb372f19a"
}

variable "ecs_cluster_instance_type" {
  description = "The type of instances to run in the ECS cluster (e.g. t2.micro)"
  type        = string
  default     = "t2.micro"
}

variable "ecs_cluster_instance_keypair_name" {
  description = "The name of the Key Pair that can be used to SSH to each instance in the ECS cluster"
  type        = string
  default     = "spring-app"
}

variable "ecs_cluster_vpc_subnet_ids" {
  description = "A list of subnet ids in which the ECS cluster should be deployed."
  type        = list(string)
  #  default     = [subnet-0e922442, subnet-0e922442, subnet-b9014fc3]
}

variable "vpc_id" {
  description = "The id of the VPC in which to run the ECS cluster"
  type        = string
  default     = "vpc-f803ea93"
}

variable "container_name" {
  description = "The name of the container in the ECS Task Definition."
  type        = string
  default     = "spring-boot-app"
}

variable "service_name" {
  description = "The name of the ECS service to run"
  type        = string
  default     = "ecs-spring-boot"
}

variable "environment_name" {
  description = "The environment name in which the ALB is located. (e.g. prod)"
  type        = string
  default     = "prod"
}

variable "container_http_port" {
  description = "The port var.docker_image listens on for HTTP requests"
  type        = number
  default     = 3000
}

variable "alb_vpc_subnet_ids" {
  description = "A list of the subnets into which the ALB will place its underlying nodes. Include one subnet per Availabability Zone. If the ALB is public-facing, these should be public subnets. Otherwise, they should be private subnets."
  type        = list(string)
  #  default = [
  #    "subnet-0e922442",
  #    "subnet-2289984a",
  #    "subnet-b9014fc3"
  #  ]
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
  default     = 512
}
