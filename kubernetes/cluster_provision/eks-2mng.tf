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

  eks_managed_node_groups = {
    tools = {
      name            = "${var.project_name}-nodegroup-tools"
      ami_type        = "BOTTLEROCKET_ARM_64" # BOTTLEROCKET_ARM_64 or BOTTLEROCKET_x86_64
      instance_types  = ["c6g.large"]
      iam_role_name   = "${var.project_name}-ng-tools"
      use_name_prefix = false

      min_size     = 2
      max_size     = 27
      desired_size = 2

      launch_template_tags = {
        Name = "${var.project_name}-node-tools"
      }

      labels = {
        dedicated = "tools"
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_put_response_hop_limit = 1
        http_tokens                 = "required"
      }
    }

    apps = {
      name            = "${var.project_name}-nodegroup-apps"
      ami_type        = "BOTTLEROCKET_ARM_64" # BOTTLEROCKET_ARM_64 or BOTTLEROCKET_x86_64
      instance_types  = ["c6g.xlarge"]
      iam_role_name   = "${var.project_name}-ng-apps"
      use_name_prefix = false

      min_size     = 2
      max_size     = 27
      desired_size = 2

      launch_template_tags = {
        Name = "${var.project_name}-node-apps"
      }

      labels = {
        dedicated = "apps"
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

  cluster_security_group_additional_rules = {
    bastion = {
      protocol    = "tcp"
      from_port   = "443"
      to_port     = "443"
      cidr_blocks = ["10.0.0.0/8"]
      type        = "ingress"
    }
  }

  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::648911607072:role/us-unicorn-role-bastion"

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
