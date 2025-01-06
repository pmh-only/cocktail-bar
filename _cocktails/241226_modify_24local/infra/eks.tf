module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-eks-cluster"
  cluster_version = "1.31"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.project_name}-cluster"
  }

  eks_managed_node_groups = {
    skills-eks-addon-nodegroup = {
      use_name_prefix = false
      ami_type        = "BOTTLEROCKET_ARM_64"
      instance_types  = ["t4g.large"]
      iam_role_name   = "skills-eks-app-nodegroup"

      min_size     = 2
      max_size     = 27
      desired_size = 2

      launch_template_tags = {
        Name = "skills-eks-addon-node"
      }
    }

    skills-eks-app-nodegroup = {
      use_name_prefix = false
      ami_type        = "BOTTLEROCKET_ARM_64"
      instance_types  = ["m6g.large"]
      iam_role_name   = "skills-eks-app-nodegroup"

      min_size     = 2
      max_size     = 27
      desired_size = 2

      launch_template_tags = {
        Name = "skills-eks-app-node"
      }

      labels = {
        dedicated = "app"
      }

      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "app"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  fargate_profiles = {
    skills-eks-app-profile = {
      name = "skills-eks-app-profile"
      selectors = [
        {
          namespace = "skills"
          labels = {
            app = "token"
          }
        }
      ]

      iam_role_additional_policies = {
        CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
      }

      subnet_ids = module.vpc.private_subnets
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

resource "aws_security_group_rule" "dns53" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [module.eks.cluster_primary_security_group_id]
  security_group_id = module.eks.node_security_group_id
}
