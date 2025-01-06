module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets  = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
  private_subnets = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
  intra_subnets = ["10.10.20.0/24", "10.10.21.0/24", "10.10.22.0/24"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "karpenter.sh/discovery" = "${var.project_name}-cluster"
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_names = ["${var.project_name}-subnet-public-a", "${var.project_name}-subnet-public-b", "${var.project_name}-subnet-public-c"]
  private_subnet_names = ["${var.project_name}-subnet-private-a", "${var.project_name}-subnet-private-b", "${var.project_name}-subnet-private-c"]
  intra_subnet_names = ["${var.project_name}-subnet-protected-a", "${var.project_name}-subnet-protected-b", "${var.project_name}-subnet-protected-c"]

  default_route_table_name = "${var.project_name}-rtb-default"
  public_route_table_tags = { Name = "${var.project_name}-rtb-public" }
  intra_route_table_tags = { Name = "${var.project_name}-rtb-protected" }

  igw_tags = { Name = "${var.project_name}-igw" }

  enable_flow_log = true
  create_flow_log_cloudwatch_iam_role = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support = true
  enable_dns_hostnames = true
  enable_nat_gateway = true  
}

locals {
  private_route_table_names = ["${var.project_name}-rtb-private-a", "${var.project_name}-rtb-private-b", "${var.project_name}-rtb-private-c"]
  nat_gateway_names = ["${var.project_name}-natgw-a", "${var.project_name}-natgw-b", "${var.project_name}-natgw-c"]
}

resource "null_resource" "change_private_rtb_name" {
  count = length(local.private_route_table_names)
  triggers = { _ = timestamp() }

  depends_on = [
    module.vpc
  ]

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${module.vpc.private_route_table_ids[count.index]} --tags Key=Name,Value=${local.private_route_table_names[count.index]}"
  }
}

resource "null_resource" "change_nat_gateway_name" {
  count = length(local.nat_gateway_names)
  triggers = { _ = timestamp() }

  depends_on = [
    module.vpc
  ]

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${module.vpc.natgw_ids[count.index]} --tags Key=Name,Value=${local.nat_gateway_names[count.index]}"
  }
}

output "tgw_target_vpc_id" {
  value = module.vpc.vpc_id
}

output "tgw_target_subnet" {
  value = length(module.vpc.intra_subnets) > 0 ? module.vpc.intra_subnets : module.vpc.private_subnets
}
