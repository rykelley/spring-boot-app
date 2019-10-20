
variable "aws_region" {
  description = "The AWS Region where this VPC will exist."
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC. Examples include 'prod', 'dev', 'mgmt', etc."
  type        = string
}

variable "cidr_block" {
  description = "The IP address range of the VPC in CIDR notation. A prefix of /18 is recommended. Do not use a prefix higher than /27. Examples include '10.100.0.0/18', '10.200.0.0/18', etc."
  type        = string
}

variable "num_nat_gateways" {
  description = "The number of NAT Gateways to launch for this VPC. For production VPCs, a NAT Gateway should be placed in each Availability Zone (so likely 3 total), whereas for non-prod VPCs, just one Availability Zone (and hence 1 NAT Gateway) will suffice."
  type        = number
}

variable "num_availability_zones" {
  description = "How many AWS Availability Zones (AZs) to use. One subnet of each type (public, private app, private persistence) will be created in each AZ. Note that this must be less than or equal to the total number of AZs in a region. A value of null means all AZs should be used. For example, if you specify 3 in a region with 5 AZs, subnets will be created in just 3 AZs instead of all 5."
  type        = number
  default     = null
}


variable "use_custom_nat_eips" {
  description = "Set to true to use existing EIPs, passed in via var.custom_nat_eips, for the NAT gateway(s), instead of creating new ones."
  type        = bool
  default     = false
}

variable "custom_nat_eips" {
  description = "The list of EIPs (allocation ids) to use for the NAT gateways. Their number has to match the one given in 'num_nat_gateways'. Must be set if var.use_custom_nat_eips us true."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidr_blocks" {
  description = "A map listing the specific CIDR blocks desired for each public subnet. The key must be in the form AZ-0, AZ-1, ... AZ-n where n is the number of Availability Zones. If left blank, we will compute a reasonable CIDR block for each subnet."
  type        = map(string)
  default     = {}
  # Example:
  # default = {
  #    AZ-0 = "10.226.20.0/24"
  #    AZ-1 = "10.226.21.0/24"
  #    AZ-2 = "10.226.22.0/24"
  # }
}

variable "private_app_subnet_cidr_blocks" {
  description = "A map listing the specific CIDR blocks desired for each private-app subnet. The key must be in the form AZ-0, AZ-1, ... AZ-n where n is the number of Availability Zones. If left blank, we will compute a reasonable CIDR block for each subnet."
  type        = map(string)
  default     = {}
  # Example:
  # default = {
  #    AZ-0 = "10.226.30.0/24"
  #    AZ-1 = "10.226.31.0/24"
  #    AZ-2 = "10.226.32.0/24"
  # }
}



variable "private_propagating_vgws" {
  description = "A list of Virtual Gateways that will propagate routes to private subnets. All routes from VPN connections that use Virtual Gateways listed here will appear in route tables of private subnets. If left empty, no routes will be propagated."
  type        = list(string)
  default     = []
  # Example:
  #  default = ["vgw-07bf8d1a"]
}

variable "tenancy" {
  description = "The allowed tenancy of instances launched into the selected VPC. Must be one of: default, dedicated, or host."
  type        = string
  default     = "default"
}

variable "custom_tags" {
  description = "A map of tags to apply to the VPC, Subnets, Route Tables, and Internet Gateway. The key is the tag name and the value is the tag value. Note that the tag 'Name' is automatically added by this module but may be optionally overwritten by this variable."
  type        = map(string)
  default     = {}
}

variable "public_subnet_custom_tags" {
  description = "A map of tags to apply to the public Subnet, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "private_app_subnet_custom_tags" {
  description = "A map of tags to apply to the private-app Subnet, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}


variable "nat_gateway_custom_tags" {
  description = "A map of tags to apply to the NAT gateways, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "subnet_spacing" {
  description = "The amount of spacing between the different subnet types"
  type        = number
  default     = 10
}

variable "public_subnet_bits" {
  description = "Takes the CIDR prefix and adds these many bits to it for calculating subnet ranges.  MAKE SURE if you change this you also change the CIDR spacing or you may hit errors.  See cidrsubnet interpolation in terraform config for more information."
  type        = number
  default     = 5
}

variable "private_subnet_bits" {
  description = "Takes the CIDR prefix and adds these many bits to it for calculating subnet ranges.  MAKE SURE if you change this you also change the CIDR spacing or you may hit errors.  See cidrsubnet interpolation in terraform config for more information."
  type        = number
  default     = 5
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the public subnet should be assigned a public IP address (versus a private IP address)"
  type        = bool
  default     = false
}
