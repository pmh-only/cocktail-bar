module "eks2" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "prod-1000"
  cluster_version = "1.30"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    prod-1000 = {
      name = "prod-1000-ng"
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3.medium"]
      iam_role_name = "prod-1000-ng"

      min_size     = 2
      max_size     = 27
      desired_size = 2

      launch_template_tags = {
        Name = "prod-1000-node"
      }
    }
  }

  cluster_security_group_additional_rules = {
    bastion = {
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
      cidr_blocks = ["10.0.0.0/24"]
      type="ingress"
    }
  }

  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn = "arn:aws:iam::648911607072:role/wsc2024-bastion-role"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = []
            type       = "cluster"
          }
        }
      }
    }
  }

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}
