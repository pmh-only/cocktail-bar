module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = "1.31"

  vpc_id                   = aws_vpc.this.id
  subnet_ids               = [for item in local.eks_node_subnets : aws_subnet.this[item.key].id]
  control_plane_subnet_ids = [for item in local.eks_controlplane_subnets : aws_subnet.this[item.key].id]

  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.project_name}-cluster"
  }

  eks_managed_node_groups = {
    tools = {
      # BOTTLEROCKET_ARM_64
      # BOTTLEROCKET_x86_64
      # AL2023_ARM_64_STANDARD
      # AL2023_X86_64_STANDARD
      # AL2_ARM_64

      name            = "${var.project_name}-nodegroup-tools"
      ami_type        = "BOTTLEROCKET_ARM_64"
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

resource "aws_eks_access_entry" "karpenter" {
  principal_arn = module.eks_blueprints_addons.karpenter.node_iam_role_arn
  cluster_name  = module.eks.cluster_name
  type          = "EC2_LINUX"
}
