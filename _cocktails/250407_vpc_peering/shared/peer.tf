locals {
  peer_name = "${var.project_name}-peer"

  peer_source_vpc_id = "vpc-0fd0a7c8e07c81e69"
  peer_target_vpc_id = "vpc-0a1c743a8527ab736"

  peer_region = ""
}

# -------------------------------------------------------------------
# Data sources to discover VPC details dynamically
# -------------------------------------------------------------------

data "aws_vpc" "source_vpc" {
  id = local.peer_source_vpc_id
}

data "aws_vpc" "target_vpc" {
  id = local.peer_target_vpc_id
}

data "aws_route_tables" "source_vpc_rtb" {
  vpc_id = local.peer_source_vpc_id
}

data "aws_route_tables" "target_vpc_rtb" {
  vpc_id = local.peer_target_vpc_id
}

# -------------------------------------------------------------------
# VPC Peering resources
# -------------------------------------------------------------------

resource "aws_vpc_peering_connection" "peering" {
  peer_vpc_id = local.peer_target_vpc_id
  vpc_id      = local.peer_source_vpc_id

  peer_region = length(local.peer_region) > 0 ? local.peer_region : null
  auto_accept = true

  tags = {
    Name = local.peer_name
  }
}

resource "aws_route" "source_routes" {
  for_each = toset(data.aws_route_tables.source_vpc_rtb.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.target_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route" "target_routes" {
  for_each = toset(data.aws_route_tables.target_vpc_rtb.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.source_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}
