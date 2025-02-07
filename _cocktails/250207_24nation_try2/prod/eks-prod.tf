module "eks-prod000" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "prod-000"
  cluster_version = "1.30"

  # vpc_id                   = module.vpc.vpc_id
  # subnet_ids               = module.vpc.private_subnets
  # control_plane_subnet_ids = module.vpc.intra_subnets

  # V2
  vpc_id                   = aws_vpc.this.id
  subnet_ids               = [for item in local.eks_node_subnets : aws_subnet.this[item.key].id]
  control_plane_subnet_ids = [for item in local.eks_controlplane_subnets : aws_subnet.this[item.key].id]

  eks_managed_node_groups = {

    apps = {
      name           = "prod-000"
      ami_type       = "BOTTLEROCKET_x86_64" # BOTTLEROCKET_ARM_64 or BOTTLEROCKET_x86_64
      instance_types = ["t3.medium"]
      iam_role_name  = "${var.project_name}-prod-000"

      min_size     = 2
      max_size     = 27
      desired_size = 2

      launch_template_tags = {
        Name = "wsc2024-prod-000-node"
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
      cidr_blocks = ["0.0.0.0/0"]
      type        = "ingress"
    }
  }

  access_entries = {
  }

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}
