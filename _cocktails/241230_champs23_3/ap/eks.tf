module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = "1.31"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    ap-unicorn-nodegroup-tools = {
      use_name_prefix = false
      name = "ap-unicorn-nodegroup-tools"
      ami_type       = "BOTTLEROCKET_ARM_64"
      instance_types = ["c6g.large"]
      iam_role_name = "nodegroup-tools"

      min_size     = 1
      max_size     = 27
      desired_size = 1

      launch_template_tags = {
        Name = "ap-unicorn-node-tools"
      }
    }

    ap-unicorn-nodegroup-apps = {
      use_name_prefix = false
      name = "ap-unicorn-nodegroup-apps"
      ami_type       = "BOTTLEROCKET_ARM_64"
      instance_types = ["c6g.xlarge"]
      iam_role_name = "nodegroup-apps"

      min_size     = 0
      max_size     = 27
      desired_size = 0

      launch_template_tags = {
        Name = "ap-unicorn-node-apps"
      }

      labels = {
        app = "apps"
      }
      
      taints = {
        dedicated = {
          key = "dedicated"
          value = "app"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  cluster_security_group_additional_rules = {
    bastion = {
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
      cidr_blocks = ["10.0.0.0/8"]
      type="ingress"
    }
  }

  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn = "arn:aws:iam::648911607072:role/us-unicorn-role-bastion"

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
