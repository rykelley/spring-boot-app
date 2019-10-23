
variable "service_name" {
  description = "The name of the service. This is used to namespace all resources created by this module."
  type        = string
}

variable "environment_name" {
  description = "The environment name in which the ECS Service is located. (e.g. stage, prod)"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the ECS Cluster where this service should run."
  type        = string
}

variable "ecs_task_container_definitions" {
  description = "The JSON text of the ECS Task Container Definitions. This portion of the ECS Task Definition defines the Docker container(s) to be run along with all their properties. It should adhere to the format described at https://goo.gl/ob5U3g."
  type        = string
}

variable "custom_task_execution_name_prefix" {
  description = "Prefix for name of iam role and policy that allows cloudwatch and ecr access"
  type        = string
  default     = ""
}

variable "desired_number_of_tasks" {
  description = "How many copies of the Task to run across the cluster."
  type        = number
}

variable "use_auto_scaling" {
  description = "Set this variable to 'true' to tell the ECS service to ignore var.desired_number_of_tasks and instead use auto scaling to determine how many Tasks of this service to run."
  type        = bool
  default     = false
}

variable "deployment_maximum_percent" {
  description = "The upper limit, as a percentage of var.desired_number_of_tasks, of the number of running tasks that can be running in a service during a deployment. Setting this to more than 100 means that during deployment, ECS will deploy new instances of a Task before undeploying the old ones."
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "The lower limit, as a percentage of var.desired_number_of_tasks, of the number of running tasks that must remain running and healthy in a service during a deployment. Setting this to less than 100 means that during deployment, ECS may undeploy old instances of a Task before deploying new ones."
  type        = number
  default     = 100
}

variable "is_associated_with_elb" {
  description = "If set to true, associate this service with the Elasitc Load Balancer (ELB) in var.elb_name."
  type        = bool
  default     = false
}

variable "elb_name" {
  description = "The name of an Elastic Load Balancer (ELB) to associate with this service. Containers in the service will automatically register with the ELB when booting up. If var.is_associated_with_elb is false, this value is ignored."
  type        = string
  default     = ""
}

variable "elb_container_name" {
  description = "The name of the container, as it appears in the var.task_arn Task definition, to associate with the ELB in var.elb_name. Currently, ECS can only associate an ELB with a single container per service. If var.is_associated_with_elb is false, this value is ignored."
  type        = string
  default     = ""
}

variable "elb_container_port" {
  description = "The port on the container in var.container_name to associate with the ELB in var.elb_name. Currently, ECS can only associate an ELB with a single container per service. If var.is_associated_with_elb is false, this value is ignored."
  type        = number
  default     = null
}




variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 1800. Only valid for services configured to use load balancers."
  type        = number
  default     = 0
}

variable "volumes" {
  description = "(Optional) A list of volume blocks that containers in your task may use. Each item in the list should be a map compatible with https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html#volume-block-arguments."
  type        = list(any)
  default     = []

  # Example:
  # volumes = [
  #   {
  #     name      = "datadog"
  #     host_path = "/var/run/datadog"
  #   }
  # ]
}

variable "additional_task_assume_role_policy_principals" {
  description = "A list of additional principals who can assume the task and task execution roles"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS TASK PLACEMENT PARAMETERS
# These variables are used to determine where ecs tasks should be placed on a cluster.
#
# https://www.terraform.io/docs/providers/aws/r/ecs_service.html#placement_strategy-1
# https://www.terraform.io/docs/providers/aws/r/ecs_service.html#placement_constraints-1
#
# Since placement_strategy and placement_constraint are inline blocks and you can't use count to make them conditional,
# we give some sane defaults here
# ---------------------------------------------------------------------------------------------------------------------
variable "placement_strategy_type" {
  type    = string
  default = "binpack"
}

variable "placement_strategy_field" {
  type    = string
  default = "cpu"
}

variable "placement_constraint_type" {
  type    = string
  default = "memberOf"
}

variable "placement_constraint_expression" {
  type    = string
  default = "attribute:ecs.ami-id != 'ami-fake'"
}

variable "ecs_task_definition_network_mode" {
  description = "The Docker networking mode to use for the containers in the task. The valid values are none, bridge, awsvpc, and host"
  type        = string
  default     = "bridge"
}
