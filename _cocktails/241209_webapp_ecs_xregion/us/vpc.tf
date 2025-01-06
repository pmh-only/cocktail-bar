module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-us-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
  private_subnets = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
  intra_subnets   = ["10.10.20.0/24", "10.10.21.0/24", "10.10.22.0/24"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "karpenter.sh/discovery"          = "${var.project_name}-cluster"
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_names  = ["${var.project_name}-us-subnet-public-a", "${var.project_name}-us-subnet-public-b", "${var.project_name}-us-subnet-public-c"]
  private_subnet_names = ["${var.project_name}-us-subnet-private-a", "${var.project_name}-us-subnet-private-b", "${var.project_name}-us-subnet-private-c"]
  intra_subnet_names   = ["${var.project_name}-us-subnet-protected-a", "${var.project_name}-us-subnet-protected-b", "${var.project_name}-us-subnet-protected-c"]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = true
}
