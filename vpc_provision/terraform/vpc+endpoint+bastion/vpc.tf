module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  intra_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

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

  enable_dns_support = true
  enable_dns_hostnames = true
  enable_nat_gateway = true  
}
