module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "wsc2024-eks-cluster"
  cluster_version = "1.31"

  vpc_id                   = aws_vpc.this.id
  subnet_ids               = [for item in local.eks_node_subnets : aws_subnet.this[item.key].id]
  control_plane_subnet_ids = [for item in local.eks_controlplane_subnets : aws_subnet.this[item.key].id]

  eks_managed_node_groups = {
    other = {
      name            = "wsc2024-other-ng"
      ami_type        = "BOTTLEROCKET_x86_64" # BOTTLEROCKET_ARM_64 or BOTTLEROCKET_x86_64
      instance_types  = ["t3.medium"]
      iam_role_name   = "wsc2024-other-ng"
      use_name_prefix = false

      min_size     = 2
      max_size     = 27
      desired_size = 2

      launch_template_tags = {
        Name = "wsc2024-other-node"
      }

      labels = {
        dedicated = "other"
        app       = "other"
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_put_response_hop_limit = 1
        http_tokens                 = "required"
      }
    }

    apps = {
      name            = "wsc2024-db-application-ng"
      ami_type        = "BOTTLEROCKET_x86_64" # BOTTLEROCKET_ARM_64 or BOTTLEROCKET_x86_64
      instance_types  = ["t3.medium"]
      iam_role_name   = "wsc2024-db-application-ng"
      use_name_prefix = false

      min_size     = 2
      max_size     = 27
      desired_size = 2

      launch_template_tags = {
        Name = "wsc2024-db-application-node"
      }

      labels = {
        dedicated = "app"
        app       = "db"
      }

      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "app"
          effect = "NO_SCHEDULE"
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_put_response_hop_limit = 1
        http_tokens                 = "required"
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
