module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "dev-eks-cluster"
  cluster_version = "1.29"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  fargate_profiles = {
    fargate = {
      name = "dev-eks-fargate"
      selectors = [
        { namespace = "*" }
      ]
    }
  }

  cluster_security_group_additional_rules = {
    bastion = {
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
      source_security_group_id = aws_security_group.bastion.id
      type="ingress"
    }
  }

  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn = aws_iam_role.bastion.arn

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
