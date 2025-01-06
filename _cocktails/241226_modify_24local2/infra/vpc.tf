module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = "172.16.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnets  = ["172.16.1.0/24", "172.16.2.0/24"]
  private_subnets = ["172.16.11.0/24", "172.16.12.0/24"]

  public_subnet_names  = ["${var.project_name}-public-subnet-a", "${var.project_name}-public-subnet-b"]
  private_subnet_names = ["${var.project_name}-private-subnet-a", "${var.project_name}-private-subnet-b"]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = true
}
