variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "repo_names" {
  description = "A list of names of the apps you want to store in ECR. One ECR repository will be created for each name."
  type        = string
}
