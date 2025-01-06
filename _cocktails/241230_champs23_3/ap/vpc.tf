module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "unicorn-secondary"
  cidr = "10.101.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  public_subnets  = ["10.101.0.0/24", "10.101.1.0/24", "10.101.2.0/24"]
  private_subnets = ["10.101.3.0/24", "10.101.4.0/24", "10.101.5.0/24"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "karpenter.sh/discovery"          = "${var.project_name}-cluster"
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_names  = ["${var.project_name}-public-a", "${var.project_name}-public-b", "${var.project_name}-public-c"]
  private_subnet_names = ["${var.project_name}-private-a", "${var.project_name}-private-b", "${var.project_name}-private-c"]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = true
}
