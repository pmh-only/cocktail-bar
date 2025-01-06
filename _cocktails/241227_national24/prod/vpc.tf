module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = "172.16.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["172.16.0.0/24", "172.16.1.0/24"]
  private_subnets = ["172.16.2.0/24", "172.16.3.0/24"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_names  = ["${var.project_name}-load-sn-a", "${var.project_name}-load-sn-b"]
  private_subnet_names = ["${var.project_name}-app-sn-a", "${var.project_name}-app-sn-b"]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = true
}
