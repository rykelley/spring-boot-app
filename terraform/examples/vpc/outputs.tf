output "vpc_name" {
  value = module.vpc_app_ecs.vpc_name
}

output "vpc_id" {
  value = module.vpc_app_ecs.vpc_id
}

output "cidr_block" {
  value = module.vpc_app_ecs.vpc_cidr_block
}

output "public_subnet_cidr_blocks" {
  value = module.vpc_app_ecs.public_subnet_cidr_blocks
}

output "private_app_subnet_cidr_blocks" {
  value = module.vpc_app_ecs.private_app_subnet_cidr_blocks
}



output "public_subnet_ids" {
  value = module.vpc_app_ecs.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.vpc_app_ecs.private_app_subnet_ids
}


output "public_subnet_route_table_id" {
  value = module.vpc_app_ecs.public_subnet_route_table_id
}


output "nat_gateway_public_ips" {
  value = module.vpc_app_ecs.nat_gateway_public_ips
}

output "num_availability_zones" {
  value = module.vpc_app_ecs.num_availability_zones
}

output "availability_zones" {
  value = module.vpc_app_ecs.availability_zones
}
