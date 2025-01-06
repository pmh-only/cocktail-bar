module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = "10.100.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnets  = ["10.100.1.0/24", "10.100.2.0/24"]
  private_subnets = ["10.100.11.0/24", "10.100.12.0/24"]
  intra_subnets   = ["10.100.21.0/24", "10.100.22.0/24"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "karpenter.sh/discovery"          = "${var.project_name}-eks-cluster"
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_names  = ["${var.project_name}-public-subnet-a", "${var.project_name}-public-subnet-b"]
  private_subnet_names = ["${var.project_name}-private-subnet-a", "${var.project_name}-private-subnet-b"]
  intra_subnet_names   = ["${var.project_name}-protected-subnet-a", "${var.project_name}-protected-subnet-b"]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = true
}
