module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]

  public_subnet_names = ["${var.project_name}-mgmt-sn-a", "${var.project_name}-mgmt-sn-b"]

  enable_flow_log = true
  create_flow_log_cloudwatch_iam_role = true
  create_flow_log_cloudwatch_log_group = true

  enable_dns_support = true
  enable_dns_hostnames = true
}
