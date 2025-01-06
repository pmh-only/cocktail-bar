module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnets = ["10.10.10.0/24", "10.10.11.0/24"]
  intra_subnets   = ["10.10.20.0/24", "10.10.21.0/24"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "karpenter.sh/discovery"          = "${var.project_name}-eks-cluster"
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_names  = ["${var.project_name}-public-subnet-a", "${var.project_name}-public-subnet-b"]
  private_subnet_names = ["${var.project_name}-app-subnet-a", "${var.project_name}-app-subnet-b"]
  intra_subnet_names   = ["${var.project_name}-data-subnet-a", "${var.project_name}-data-subnet-b"]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = true
}
