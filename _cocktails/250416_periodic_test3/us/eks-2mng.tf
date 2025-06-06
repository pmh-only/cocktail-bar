module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = "1.31"

  vpc_id                   = aws_vpc.this.id
  subnet_ids               = [for item in local.eks_node_subnets : aws_subnet.this[item.key].id]
  control_plane_subnet_ids = [for item in local.eks_controlplane_subnets : aws_subnet.this[item.key].id]

  fargate_profiles = {
    # fargate = {
    #   name = "fargate"
    #   selectors = [{
    #     namespace = "fargate"
    #   }]
    # }
  }

  eks_managed_node_groups = {
    tools = {
      # BOTTLEROCKET_ARM_64
      # BOTTLEROCKET_x86_64
      # AL2023_ARM_64_STANDARD
      # AL2023_X86_64_STANDARD
      # AL2_ARM_64

      name            = "${var.project_name}-nodegroup-tools"
      ami_type        = "AL2023_ARM_64_STANDARD"
      instance_types  = ["c7g.large"]
      iam_role_name   = "${var.project_name}-ng-tools"
      use_name_prefix = false

      min_size     = 2
      max_size     = 27
      desired_size = 2

      node_repair_config = {
        enabled = true
      }

      launch_template_tags = {
        Name  = "${var.project_name}-node-tools"
        owner = "pmh_only"
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
      name = "${var.project_name}-nodegroup-apps"
      # BOTTLEROCKET_ARM_64
      # BOTTLEROCKET_x86_64
      # AL2023_ARM_64_STANDARD
      # AL2023_X86_64_STANDARD
      # AL2_ARM_64
      ami_type        = "AL2023_ARM_64_STANDARD"
      instance_types  = ["c7g.xlarge"]
      iam_role_name   = "${var.project_name}-ng-apps"
      use_name_prefix = false

      min_size     = 2
      max_size     = 27
      desired_size = 2

      node_repair_config = {
        enabled = true
      }

      launch_template_tags = {
        Name  = "${var.project_name}-node-apps"
        owner = "pmh_only"
      }

      labels = {
        dedicated = "app"
      }

      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "app"
          effect = "NO_EXECUTE"
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
    vpc = {
      protocol    = "tcp"
      from_port   = "443"
      to_port     = "443"
      cidr_blocks = ["10.0.0.0/8"]
      type        = "ingress"
    }
  }

  node_security_group_additional_rules = {
    calico-apiserver = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = "5443"
      to_port                       = "5443"
      source_cluster_security_group = true
      description                   = "Cluster API to node calico apiserver"
    }
  }

  access_entries = {
    caller = {
      principal_arn = data.aws_caller_identity.caller.arn

      policy_associations = {
        caller_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
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

  cluster_zonal_shift_config = {
    enabled = true
  }
}

resource "aws_security_group_rule" "fargate_metric_server" {
  security_group_id = module.eks.cluster_primary_security_group_id

  type      = "ingress"
  from_port = 10250
  to_port   = 10250
  protocol  = "tcp"

  source_security_group_id = module.eks.node_security_group_id
}
