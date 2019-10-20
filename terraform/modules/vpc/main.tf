


terraform {
  required_version = ">= 0.12"
}





resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags,
  )
}



resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags,
  )
}


data "aws_availability_zones" "available" {}




resource "aws_subnet" "public" {
  count             = data.template_file.num_availability_zones.rendered
  vpc_id            = aws_vpc.main.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block = lookup(
    var.public_subnet_cidr_blocks,
    "AZ-${count.index}",
    cidrsubnet(var.cidr_block, var.public_subnet_bits, count.index),
  )
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    { Name = "${var.vpc_name}-public-${count.index}" },
    var.custom_tags,
    var.public_subnet_custom_tags,
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "${var.vpc_name}-public" },
    var.custom_tags,
  )
}


resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id


  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.public,
  ]

  timeouts {
    create = "5m"
  }
}


resource "aws_route_table_association" "public" {
  count          = data.template_file.num_availability_zones.rendered
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}


resource "aws_eip" "nat" {
  count      = var.use_custom_nat_eips ? 0 : var.num_nat_gateways
  vpc        = true
  tags       = var.custom_tags
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat" {
  count = var.num_nat_gateways
  allocation_id = element(
    split(",", var.use_custom_nat_eips ? join(",", var.custom_nat_eips) : join(",", aws_eip.nat.*.id)),
    count.index,
  )
  subnet_id = element(aws_subnet.public.*.id, count.index)
  tags = merge(
    { Name = "${var.vpc_name}-nat-gateway-${count.index}" },
    var.custom_tags,
    var.nat_gateway_custom_tags,
  )


  depends_on = [aws_internet_gateway.main]
}




resource "aws_subnet" "private-app" {
  count             = data.template_file.num_availability_zones.rendered
  vpc_id            = aws_vpc.main.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block = lookup(
    var.private_app_subnet_cidr_blocks,
    "AZ-${count.index}",
    cidrsubnet(var.cidr_block, var.private_subnet_bits, count.index + var.subnet_spacing),
  )
  tags = merge(
    { Name = "${var.vpc_name}-private-app-${count.index}" },
    var.custom_tags,
    var.private_app_subnet_custom_tags,
  )
}


resource "aws_route_table" "private-app" {
  count  = data.template_file.num_availability_zones.rendered
  vpc_id = aws_vpc.main.id

  propagating_vgws = var.private_propagating_vgws

  tags = merge(
    { Name = "${var.vpc_name}-private-app-${count.index}" },
    var.custom_tags,
  )
}


resource "aws_route" "nat" {
  count                  = var.num_nat_gateways == 0 ? 0 : data.template_file.num_availability_zones.rendered
  route_table_id         = element(aws_route_table.private-app.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)


  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.private-app,
  ]

  timeouts {
    create = "5m"
  }
}


resource "aws_route_table_association" "private-app" {
  count          = data.template_file.num_availability_zones.rendered
  subnet_id      = element(aws_subnet.private-app.*.id, count.index)
  route_table_id = element(aws_route_table.private-app.*.id, count.index)
}


resource "null_resource" "vpc_ready" {
  depends_on = [
    aws_internet_gateway.main,
    aws_nat_gateway.nat,
    aws_route.internet,
    aws_route.nat,
  ]
}

data "template_file" "num_availability_zones" {
  template = var.num_availability_zones == null ? length(data.aws_availability_zones.available.names) : var.num_availability_zones
}
