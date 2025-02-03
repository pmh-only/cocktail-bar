module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = "1.31"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # V2
  # vpc_id                   = aws_vpc.this.id
  # subnet_ids               = [for item in local.eks_node_subnets : aws_subnet.this[item.key].id]
  # control_plane_subnet_ids = [for item in local.eks_controlplane_subnets : aws_subnet.this[item.key].id]

  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.project_name}-cluster"
  }

  eks_managed_node_groups = {
    project-mng-addon = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["c5.large"]

      min_size     = 3
      max_size     = 27
      desired_size = 3
    }
  }

  cluster_security_group_additional_rules = {
    bastion = {
      protocol                 = "tcp"
      from_port                = "443"
      to_port                  = "443"
      source_security_group_id = aws_security_group.bastion.id
      type                     = "ingress"
    }
  }

  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn     = aws_iam_role.bastion.arn

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

resource "aws_eks_access_entry" "karpenter" {
  principal_arn = module.eks_blueprints_addons.karpenter.node_iam_role_arn
  cluster_name  = module.eks.cluster_name
  type          = "EC2_LINUX"
}
