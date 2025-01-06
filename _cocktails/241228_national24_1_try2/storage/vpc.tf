module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = "192.168.0.0/16"

  azs                = ["us-east-1a", "us-east-1b"]
  intra_subnets      = ["192.168.0.0/24", "192.168.1.0/24"]
  intra_subnet_names = ["${var.project_name}-db-sn-a", "${var.project_name}-db-sn-b"]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support   = true
  enable_dns_hostnames = true
}
