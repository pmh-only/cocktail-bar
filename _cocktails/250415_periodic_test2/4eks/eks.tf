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

  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.project_name}-cluster"
  }

  eks_managed_node_groups = {
    apps = {
      # BOTTLEROCKET_ARM_64
      # BOTTLEROCKET_x86_64
      # AL2023_ARM_64_STANDARD
      # AL2023_X86_64_STANDARD
      # AL2_ARM_64

      name            = "${var.project_name}-nodegroup-apps"
      ami_type        = "BOTTLEROCKET_x86_64"
      instance_types  = ["c5.large"]
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

      metadata_options = {
        http_endpoint               = "enabled"
        http_put_response_hop_limit = 1
        http_tokens                 = "required"
      }
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

    vpc = {
      protocol    = "tcp"
      from_port   = "443"
      to_port     = "443"
      cidr_blocks = [local.vpc_cidr]
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
    bastion = {
      principal_arn = aws_iam_role.bastion.arn

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
