output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_name" {
  value = var.vpc_name
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_cidr_blocks" {
  value = aws_subnet.public.*.cidr_block
}

output "private_app_subnet_cidr_blocks" {
  value = aws_subnet.private-app.*.cidr_block
}


output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "private_app_subnet_ids" {
  value = aws_subnet.private-app.*.id
}



output "public_subnet_route_table_id" {
  value = aws_route_table.public.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.nat.*.id
}

output "nat_gateway_public_ips" {
  value = aws_eip.nat.*.public_ip
}

output "num_availability_zones" {
  value = data.template_file.num_availability_zones.rendered
}

output "availability_zones" {
  value = slice(data.aws_availability_zones.available.names, 0, data.template_file.num_availability_zones.rendered)
}

output "vpc_ready" {
  value = null_resource.vpc_ready.id
}
