module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnets  = ["10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.0.0/24", "10.0.1.0/24"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_names = ["${var.project_name}-public-a", "${var.project_name}-public-b"]
  private_subnet_names = ["${var.project_name}-private-a", "${var.project_name}-private-b"]

  enable_flow_log = true
  create_flow_log_cloudwatch_iam_role = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support = true
  enable_dns_hostnames = true
  enable_nat_gateway = true  
}
