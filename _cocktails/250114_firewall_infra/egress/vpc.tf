locals {
  # Number of Availability Zones
  az_count             = 2  # Adjust this as needed
  az_override_suffixes = [] # Example: ["a", "b"]

  # VPC Configuration
  vpc_cidr = "10.150.0.0/16"
  vpc_name = "${var.project_name}-vpc-egress"

  # Customizable Karpenter Discovery Tag
  karpenter_discovery_tag = "${var.project_name}-cluster"

  # Subnet toggles
  enable_public_subnets  = true
  enable_private_subnets = true
  enable_intra_subnets   = true


  # Switches to enable or disable tagging for specific route tables
  enable_separate_public_rtb = true
  enable_separate_intra_rtb  = true

  # Subnet Allocation Pattern
  subnet_patterns = {
    public  = { start_index = 0, count_per_az = 1 },
    private = { start_index = 10, count_per_az = 1 },
    intra   = { start_index = 20, count_per_az = 1 }
  }

  # Format strings for resource names
  # $1 - var.project_name
  # $2 - Availability zone (one letter)
  name_formats = {
    subnet = {
      public  = "$1-subnet-egress-public-$2",   # Example: project-subnet-public-a
      private = "$1-subnet-egress-private-$2",  # Example: project-subnet-private-a
      intra   = "$1-subnet-egress-protected-$2" # Example: project-subnet-protected-a
    },
    route_table = {
      public  = "$1-rtb-egress-public-$2",    # Example: project-rtb-public-a
      private = "$1-rtb-egress-private-$2",   # Example: project-rtb-private-a
      intra   = "$1-rtb-egress-protected-$2", # Example: project-rtb-protected-a
      default = "$1-rtb-egress-default"       # Example: project-rtb-default
    },
    nat_gateway = "$1-egress-natgw-$2", # Example: project-natgw-a
    igw         = "$1-egress-igw"       # Example: project-igw
  }
}

locals {
  # Determine final AZs
  valid_azs   = [for az in data.aws_availability_zones.available.names : az if !strcontains(az, "wlz")]
  az_override = [for suffix in local.az_override_suffixes : "${var.region}${suffix}"]
  final_azs   = length(local.az_override_suffixes) > 0 ? local.az_override : local.valid_azs

  # Slice the final AZs to limit to the required count
  azs = slice(local.final_azs, 0, local.az_count)

  # Extract AZ suffixes (e.g., "a", "b", "c") from AZ names
  az_suffixes = [for az in local.azs : substr(az, length(az) - 1, 1)]

  # Route Table Names
  route_table_names = {
    public = local.enable_public_subnets ? [
      for idx, az in local.azs : replace(
        replace(local.name_formats.route_table.public, "$1", var.project_name),
        "$2",
        local.az_suffixes[idx]
      )
    ] : [],
    private = local.enable_private_subnets ? [
      for idx, az in local.azs : replace(
        replace(local.name_formats.route_table.private, "$1", var.project_name),
        "$2",
        local.az_suffixes[idx]
      )
    ] : [],
    intra = local.enable_intra_subnets ? [
      for idx, az in local.azs : replace(
        replace(local.name_formats.route_table.intra, "$1", var.project_name),
        "$2",
        local.az_suffixes[idx]
      )
    ] : [],
    default = replace(local.name_formats.route_table.default, "$1", var.project_name)
  }

  # Subnet Names
  subnet_names = {
    public = local.enable_public_subnets ? [
      for idx, az in local.azs : replace(
        replace(local.name_formats.subnet.public, "$1", var.project_name),
        "$2",
        local.az_suffixes[idx]
      )
    ] : [],
    private = local.enable_private_subnets ? [
      for idx, az in local.azs : replace(
        replace(local.name_formats.subnet.private, "$1", var.project_name),
        "$2",
        local.az_suffixes[idx]
      )
    ] : [],
    intra = local.enable_intra_subnets ? [
      for idx, az in local.azs : replace(
        replace(local.name_formats.subnet.intra, "$1", var.project_name),
        "$2",
        local.az_suffixes[idx]
      )
    ] : []
  }

  # NAT Gateway Names
  nat_gateway_names = local.enable_public_subnets ? [
    for idx, az in local.azs : replace(
      replace(local.name_formats.nat_gateway, "$1", var.project_name),
      "$2",
      local.az_suffixes[idx]
    )
  ] : []

  # Internet Gateway Name
  igw_name = replace(local.name_formats.igw, "$1", var.project_name)

  # Subnet CIDRs by Type
  subnet_cidrs_by_type = {
    public = local.enable_public_subnets ? flatten([
      for az_idx in range(0, length(local.azs)) : [
        for i in range(0, local.subnet_patterns.public.count_per_az) :
        cidrsubnet(local.vpc_cidr, 8, local.subnet_patterns.public.start_index + (az_idx * local.subnet_patterns.public.count_per_az) + i)
      ]
    ]) : [],
    private = local.enable_private_subnets ? flatten([
      for az_idx in range(0, length(local.azs)) : [
        for i in range(0, local.subnet_patterns.private.count_per_az) :
        cidrsubnet(local.vpc_cidr, 8, local.subnet_patterns.private.start_index + (az_idx * local.subnet_patterns.private.count_per_az) + i)
      ]
    ]) : [],
    intra = local.enable_intra_subnets ? flatten([
      for az_idx in range(0, length(local.azs)) : [
        for i in range(0, local.subnet_patterns.intra.count_per_az) :
        cidrsubnet(local.vpc_cidr, 8, local.subnet_patterns.intra.start_index + (az_idx * local.subnet_patterns.intra.count_per_az) + i)
      ]
    ]) : []
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.vpc_name
  cidr = local.vpc_cidr

  azs = local.azs

  public_subnets  = local.enable_public_subnets ? local.subnet_cidrs_by_type.public : []
  private_subnets = local.enable_private_subnets ? local.subnet_cidrs_by_type.private : []
  intra_subnets   = local.enable_intra_subnets ? local.subnet_cidrs_by_type.intra : []

  public_subnet_tags = local.enable_public_subnets ? {
    "kubernetes.io/role/elb" = "1",
    Type                     = "public"
  } : {}

  private_subnet_tags = local.enable_private_subnets ? {
    "karpenter.sh/discovery"          = local.karpenter_discovery_tag,
    "kubernetes.io/role/internal-elb" = "1",
    Type                              = "private"
  } : {}

  intra_subnet_tags = local.enable_intra_subnets ? {
    Type = "intra"
  } : {}

  public_subnet_names  = local.subnet_names.public
  private_subnet_names = local.subnet_names.private
  intra_subnet_names   = local.subnet_names.intra

  default_route_table_name = local.route_table_names.default
  public_route_table_tags  = local.enable_public_subnets ? { Name = local.route_table_names.public[0] } : {}
  private_route_table_tags = local.enable_private_subnets ? { Name = local.route_table_names.private[0] } : {}
  intra_route_table_tags   = local.enable_intra_subnets ? { Name = local.route_table_names.intra[0] } : {}

  create_multiple_intra_route_tables  = local.enable_separate_intra_rtb
  create_multiple_public_route_tables = local.enable_separate_public_rtb

  igw_tags = { Name = local.igw_name }

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  flow_log_cloudwatch_log_group_retention_in_days = 7

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = local.enable_private_subnets
}

resource "null_resource" "change_public_rtb_name" {
  count = local.enable_separate_public_rtb ? length(local.route_table_names.public) : 0

  triggers = {
    timestamp = timestamp()
    rtb_id    = local.enable_separate_public_rtb ? module.vpc.public_route_table_ids[count.index] : null
  }

  depends_on = [module.vpc]

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${module.vpc.public_route_table_ids[count.index]} --tags Key=Name,Value=${local.route_table_names.public[count.index]} --region ${var.region}"
  }
}

resource "null_resource" "change_private_rtb_name" {
  count = length(local.route_table_names.private)

  triggers = {
    timestamp = timestamp()
    rtb_id    = module.vpc.private_route_table_ids[count.index]
  }

  depends_on = [module.vpc]

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${module.vpc.private_route_table_ids[count.index]} --tags Key=Name,Value=${local.route_table_names.private[count.index]} --region ${var.region}"
  }
}

resource "null_resource" "change_intra_rtb_name" {
  count = local.enable_separate_intra_rtb ? length(local.route_table_names.intra) : 0

  triggers = {
    timestamp = timestamp()
    rtb_id    = local.enable_separate_intra_rtb ? module.vpc.intra_route_table_ids[count.index] : null
  }

  depends_on = [module.vpc]

  provisioner "local-exec" {

    command = "aws ec2 create-tags --resources ${module.vpc.intra_route_table_ids[count.index]} --tags Key=Name,Value=${local.route_table_names.intra[count.index]} --region ${var.region}"
  }
}

resource "null_resource" "change_nat_gateway_name" {
  count = local.enable_private_subnets ? length(local.nat_gateway_names) : 0

  triggers = {
    timestamp = timestamp()
    natgw_id  = module.vpc.natgw_ids[count.index]
  }

  depends_on = [module.vpc]

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${module.vpc.natgw_ids[count.index]} --tags Key=Name,Value=${local.nat_gateway_names[count.index]} --region ${var.region}"
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
