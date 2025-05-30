locals {
  az_count    = 2
  az_override = [] # Example: ["a", "b"]

  # Enable/disable NAT Gateways and Internet Gateway via locals.
  enable_natgw = true
  enable_igw   = true

  # Naming format strings; placeholders: 
  # $1 = project_name, $2 = AZ (lowercase), $3 = AZ (uppercase)
  vpc_cidr         = "10.0.0.0/16"
  vpc_name         = "$1-vpc"
  igw_name         = "$1-igw"
  natgw_name       = "$1-natgw-$2"
  default_rtb_name = "$1-rtb-default"

  eks_discovery_tag = "$1-cluster"

  # Define one or more subnet groups.
  # type=public, Attach Internet Gateway Route
  # type=private, Attach NAT Gateway Route
  # type=intra, No internet connections
  subnets = [
    {
      type = "public"

      separate_rtb_per_az = true

      create_rds_subnet_group         = false
      create_elasticache_subnet_group = false
      create_redshift_subnet_group    = false

      create_vpc_endpoint = false
      create_client_vpn   = false

      create_eks_controlplane = false
      create_ecs_node         = false
      tag_eks_node            = false

      tag_tgw_attachment = false
      tag_alb_public     = true
      tag_alb_private    = false

      name     = "$1-subnet-public-$2"
      rtb_name = "$1-rtb-public-$2"
      cidr_pattern = {
        start_index     = 0
        step_per_subnet = 1
        override        = []
      }
      additional_tags = {
        "zone-type" = "public"
      }
    },
    {
      type = "private"

      separate_rtb_per_az = true

      create_rds_subnet_group         = false
      create_elasticache_subnet_group = false
      create_redshift_subnet_group    = false

      create_vpc_endpoint = false
      create_client_vpn   = false

      create_eks_controlplane = false
      create_ecs_node         = true
      tag_eks_node            = true

      tag_tgw_attachment = false
      tag_alb_public     = false
      tag_alb_private    = true

      name     = "$1-subnet-private-$2"
      rtb_name = "$1-rtb-private-$2"
      cidr_pattern = {
        start_index     = 10
        step_per_subnet = 1
        override        = []
      }
      additional_tags = {
        "zone-type" = "private"
      }
    },
    {
      type = "intra"

      separate_rtb_per_az = true

      create_rds_subnet_group         = true
      create_elasticache_subnet_group = true
      create_redshift_subnet_group    = true

      create_vpc_endpoint = true
      create_client_vpn   = false

      create_eks_controlplane = true
      create_ecs_node         = false
      tag_eks_node            = false

      tag_tgw_attachment = true
      tag_alb_public     = false
      tag_alb_private    = false

      name     = "$1-subnet-protected-$2"
      rtb_name = "$1-rtb-protected-$2"
      cidr_pattern = {
        start_index     = 20
        step_per_subnet = 1
        override        = []
      }
      additional_tags = {
        "zone-type" = "intra"
      }
    }
  ]

  enabled_gateway_endpoints = [
    "s3",
    # "dynamodb"
  ]

  enabled_interface_endpoints = [
    "ssm",
    "ssmmessages",
    "ec2messages",

    "ecr.api",
    "ecr.dkr",

    # "ecs",
    # "ecs-agent",
    # "ecs-telemetry",

    # "autoscaling",
    # "logs",
    # "ec2",
    # "sts",
    # "sqs",
    # "sns",
    # "glue",
    # "rds",
    # "secretsmanager",
    # "vpc-lattice",
    # "elasticloadbalancing",
    # "elasticfilesystem"
  ]
}

###############################################################################
# Compute Availability Zones & Suffixes
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  final_azs   = length(local.az_override) > 0 ? [for suffix in local.az_override : "${var.region}${suffix}"] : slice(data.aws_availability_zones.available.names, 0, local.az_count)
  az_suffixes = [for az in local.final_azs : substr(az, length(az) - 1, 1)]
}

###############################################################################
# Flatten Subnet Definitions Across AZs
###############################################################################

locals {
  all_subnets = flatten([
    for group_index, s in local.subnets : [
      for az_index, az in local.final_azs : {
        group_index = group_index
        az_index    = az_index
        group       = s
        az          = az
        az_suffix   = local.az_suffixes[az_index]
        cidr_index  = s.cidr_pattern.start_index + az_index * s.cidr_pattern.step_per_subnet
        key         = "${group_index}-${az_index}"
      }
    ]
  ])
  all_subnets_map = { for item in local.all_subnets : item.key => item }
}

###############################################################################
# Build a Mapping of Subnets
###############################################################################

locals {
  public_subnets_per_az = { for az in local.final_azs :
    az => [for item in local.all_subnets : item if item.group.type == "public" && item.az == az]
  }
  private_subnets_per_az = { for az in local.final_azs :
    az => [for item in local.all_subnets : item if item.group.type == "private" && item.az == az]
  }
  intra_subnets_per_az = { for az in local.final_azs :
    az => [for item in local.all_subnets : item if item.group.type == "intra" && item.az == az]
  }

  endpoint_subnets = [for item in local.all_subnets : item if item.group.create_vpc_endpoint == true]
  vpn_subnets      = [for item in local.all_subnets : item if item.group.create_client_vpn == true]

  eks_node_subnets         = [for item in local.all_subnets : item if item.group.tag_eks_node == true]
  ecs_cluster_subnets      = [for item in local.all_subnets : item if item.group.create_ecs_node == true]
  eks_controlplane_subnets = [for item in local.all_subnets : item if item.group.create_eks_controlplane == true]
}

###############################################################################
# VPC & Optional Internet Gateway
###############################################################################

resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = replace(replace(replace(local.vpc_name, "$1", var.project_name), "$2", ""), "$3", "")
  }
}

resource "aws_internet_gateway" "this" {
  count  = local.enable_igw ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = {
    Name = replace(replace(replace(local.igw_name, "$1", var.project_name), "$2", ""), "$3", "")
  }
}

###############################################################################
# Create Subnets Dynamically
###############################################################################

resource "aws_subnet" "this" {
  for_each                = { for item in local.all_subnets : item.key => item }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = length(each.value.group.cidr_pattern.override) > each.value.az_index ? each.value.group.cidr_pattern.override[each.value.az_index] : cidrsubnet(local.vpc_cidr, 8, each.value.cidr_index)
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.group.type == "public" ? true : false
  tags = merge(
    {
      Name = replace(replace(replace(each.value.group.name, "$1", var.project_name), "$2", each.value.az_suffix), "$3", upper(each.value.az_suffix))
      Type = each.value.group.type

      Peer                              = each.value.group.tag_tgw_attachment ? "true" : "false"
      "kubernetes.io/role/elb"          = each.value.group.tag_alb_public ? "1" : "0"
      "kubernetes.io/role/internal-elb" = each.value.group.tag_alb_private ? "1" : "0"

      "karpenter.sh/discovery" = each.value.group.tag_eks_node ? replace(replace(replace(local.eks_discovery_tag, "$1", var.project_name), "$2", ""), "$3", "") : "nothing"

      "kubernetes.io/cluster/${replace(replace(replace(local.eks_discovery_tag, "$1", var.project_name), "$2", ""), "$3", "")}" = "owned"
    },
    each.value.group.additional_tags
  )
}

###############################################################################
# Create Route Tables Dynamically
###############################################################################

locals {
  route_tables = flatten([
    for group_index, s in local.subnets : concat(
      (lookup(s, "separate_rtb_per_az", false) || (s.type == "private" && local.enable_natgw)) ?
      [for az_index, az in local.final_azs : {
        group_index = group_index
        az_index    = az_index
        az_suffix   = local.az_suffixes[az_index]
        group       = s
        key         = "${group_index}-${az_index}"
      }]
      : [{
        group_index = group_index,
        az_index    = null, # Added to ensure consistent type
        az_suffix   = null, # Added to ensure consistent type
        group       = s,
        key         = "${group_index}"
      }],
      []
    )
  ])
  rt_mapping = { for rt in local.route_tables : rt.key => rt }
}

resource "aws_route_table" "this" {
  for_each = { for rt in local.route_tables : rt.key => rt }
  vpc_id   = aws_vpc.this.id
  tags = {
    Name = (each.value.group.separate_rtb_per_az || (each.value.group.type == "private" && local.enable_natgw)) ? replace(replace(replace(each.value.group.rtb_name, "$1", var.project_name), "$2", each.value.az_suffix), "$3", upper(each.value.az_suffix)) : replace(replace(replace(each.value.group.rtb_name, "$1", var.project_name), "$2", ""), "$3", "")
  }
}

###############################################################################
# Associate Subnets with Route Tables
###############################################################################

resource "aws_route_table_association" "this" {
  for_each       = aws_subnet.this
  subnet_id      = each.value.id
  route_table_id = (local.all_subnets_map[each.key].group.separate_rtb_per_az || (local.all_subnets_map[each.key].group.type == "private" && local.enable_natgw)) ? aws_route_table.this["${local.all_subnets_map[each.key].group_index}-${local.all_subnets_map[each.key].az_index}"].id : aws_route_table.this["${local.all_subnets_map[each.key].group_index}"].id
}

###############################################################################
# NAT Gateways (One per AZ)
###############################################################################

resource "aws_eip" "nat" {
  for_each = local.enable_natgw ? { for az in local.final_azs : az => az } : {}
}

resource "aws_nat_gateway" "this" {
  for_each      = local.enable_natgw ? { for az in local.final_azs : az => az } : {}
  allocation_id = aws_eip.nat[each.key].id
  # Choose a public subnet from the given AZ (first one found)
  subnet_id = length(local.public_subnets_per_az[each.key]) > 0 ? aws_subnet.this[local.public_subnets_per_az[each.key][0].key].id : ""
  tags = {
    Name = length(local.public_subnets_per_az[each.key]) > 0 ? replace(replace(replace(local.natgw_name, "$1", var.project_name), "$2", local.public_subnets_per_az[each.key][0].az_suffix), "$3", upper(local.public_subnets_per_az[each.key][0].az_suffix)) : ""
  }
}

###############################################################################
# Create Private Routes for NAT Gateway (using subnet type for filtering)
###############################################################################

resource "aws_route" "private_nat" {
  for_each = local.enable_natgw ? {
    for rt in local.route_tables : rt.key => rt if rt.group.type == "private"
  } : {}

  route_table_id         = aws_route_table.this[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[local.final_azs[tonumber(each.value.az_index)]].id
}

###############################################################################
# Create Public Routes for Internet Gateway (using subnet type for filtering)
###############################################################################

resource "aws_route" "public_igw" {
  for_each = local.enable_igw ? {
    for rt in local.route_tables : rt.key => rt if rt.group.type == "public"
  } : {}

  route_table_id         = aws_route_table.this[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

###############################################################################
# Subnet Groups for Intra Subnets (if Enabled)
###############################################################################

resource "aws_db_subnet_group" "rds" {
  for_each   = { for idx, s in local.subnets : idx => s if lookup(s, "create_rds_subnet_group", false) }
  name       = "${var.project_name}-subnets-${each.key}"
  subnet_ids = [for item in local.all_subnets : aws_subnet.this[item.key].id if tostring(item.group_index) == each.key]
  tags = {
    Name = "${var.project_name}-subnets-${each.key}"
  }
}

resource "aws_elasticache_subnet_group" "elasticache" {
  for_each   = { for idx, s in local.subnets : idx => s if lookup(s, "create_elasticache_subnet_group", false) }
  name       = "${var.project_name}-subnets-${each.key}"
  subnet_ids = [for item in local.all_subnets : aws_subnet.this[item.key].id if tostring(item.group_index) == each.key]
  tags = {
    Name = "${var.project_name}-subnets-${each.key}"
  }
}

resource "aws_redshift_subnet_group" "redshift" {
  for_each   = { for idx, s in local.subnets : idx => s if lookup(s, "create_redshift_subnet_group", false) }
  name       = "${var.project_name}-subnets-${each.key}"
  subnet_ids = [for item in local.all_subnets : aws_subnet.this[item.key].id if tostring(item.group_index) == each.key]
  tags = {
    Name = "${var.project_name}-subnets-${each.key}"
  }
}

###############################################################################
# Default Route Table
###############################################################################

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.this.default_route_table_id
  tags = {
    Name = replace(replace(replace(local.default_rtb_name, "$1", var.project_name), "$2", ""), "$3", "")
  }
}

###############################################################################
# VPC Endpoints
###############################################################################

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id                     = aws_vpc.this.id
  create_security_group      = true
  security_group_name        = "${var.project_name}-sg-endpoints"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      protocol    = "tcp"
      from_port   = "443"
      to_port     = "443"
      cidr_blocks = [aws_vpc.this.cidr_block]
    }
  }

  endpoints = merge(
    { for gateway in local.enabled_gateway_endpoints : gateway => {
      service         = gateway
      service_type    = "Gateway"
      route_table_ids = values(aws_route_table.this)[*].id
      tags            = { Name = "${var.project_name}-endpoint-${gateway}" }
      }
    },
    { for interface in local.enabled_interface_endpoints : interface => {
      service             = interface
      private_dns_enabled = true
      subnet_ids          = [for item in local.endpoint_subnets : aws_subnet.this[item.key].id]
      tags                = { Name = "${var.project_name}-endpoint-${interface}" }
      } if length(local.endpoint_subnets) > 0
    }
  )
}

###############################################################################
# Client VPN
###############################################################################

module "ec2_client_vpn" {
  source = "cloudposse/ec2-client-vpn/aws"
  name   = "${var.project_name}-vpn"

  enabled = length(local.vpn_subnets) > 0

  vpc_id             = aws_vpc.this.id
  client_cidr        = "10.254.0.0/16"
  organization_name  = "${var.project_name}-org"
  associated_subnets = [for item in local.vpn_subnets : aws_subnet.this[item.key].id]

  logging_enabled     = true
  logging_stream_name = "vpnlog"
  split_tunnel        = true

  authorization_rules = [
    {
      authorize_all_groups = true
      target_network_cidr  = local.vpc_cidr
      description          = "Authorized VPC Range"
    }
  ]

  export_client_certificate = true
}

resource "local_sensitive_file" "client_configuration" {
  count = length(local.vpn_subnets) > 0 ? 1 : 0

  filename = "./temp/vpn.ovpn"
  content  = module.ec2_client_vpn.full_client_configuration
}

###############################################################################
# VPC Flowlog to Cloudwatch
###############################################################################

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${replace(replace(replace(local.vpc_name, "$1", var.project_name), "$2", ""), "$3", "")}"
  retention_in_days = 7
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name_prefix = "${var.project_name}-role-flowlog-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name_prefix = "${var.project_name}-policy-flowlog-"
  role        = aws_iam_role.vpc_flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_flow_log" "example" {
  vpc_id               = aws_vpc.this.id
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  iam_role_arn         = aws_iam_role.vpc_flow_log_role.arn

  tags = {
    Name = "${replace(replace(replace(local.vpc_name, "$1", var.project_name), "$2", ""), "$3", "")}-flowlog"
  }
}

###############################################################################
# Outputs
###############################################################################

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

locals {
  vpc_id  = aws_vpc.this.id
  vpc_azs = local.final_azs

  vpc_subnet_ids_by_group         = [for group_index, _ in local.subnets : [for subnet in local.all_subnets : aws_subnet.this[subnet.key].id if group_index == subnet.group_index]]
  vpc_public_subnet_ids_by_group  = [for group_index, group in local.subnets : [for subnet in local.all_subnets : aws_subnet.this[subnet.key].id if group_index == subnet.group_index] if group.type == "public"]
  vpc_private_subnet_ids_by_group = [for group_index, group in local.subnets : [for subnet in local.all_subnets : aws_subnet.this[subnet.key].id if group_index == subnet.group_index] if group.type == "private"]
  vpc_intra_subnet_ids_by_group   = [for group_index, group in local.subnets : [for subnet in local.all_subnets : aws_subnet.this[subnet.key].id if group_index == subnet.group_index] if group.type == "intra"]

  vpc_rds_subnet_group_names         = [for group in aws_db_subnet_group.rds : group.name]
  vpc_redshift_subnet_group_names    = [for group in aws_redshift_subnet_group.redshift : group.name]
  vpc_elasticache_subnet_group_names = [for group in aws_elasticache_subnet_group.elasticache : group.name]
}
