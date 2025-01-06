module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-eks-cluster"
  cluster_version = "1.31"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.project_name}-eks-cluster"
  }

  eks_managed_node_groups = {
    project-mng-addon = {
      ami_type       = "BOTTLEROCKET_ARM_64"
      instance_types = ["c6g.xlarge"]

      min_size     = 2
      max_size     = 27
      desired_size = 2
      # taints = [{
      #   key = "dedicated"
      #   value = "addon"
      #   effect = "NO_SCHEDULE"
      # }]
    }
  }

  # enable_cluster_creator_admin_permissions = true

  access_entries = {
    # One access entry with a policy associated
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::648911607072:role/us-wsi-role-bastion"

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
    karpenter = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.caller.account_id}:role/karpenter-ap-wsi-eks-cluster-20241212022118687100000007"
      type          = "EC2_LINUX"
    }
  }
}
