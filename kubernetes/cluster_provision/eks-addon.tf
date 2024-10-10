module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_karpenter = true
  enable_cert_manager = true
  enable_metrics_server = true
  enable_cluster_autoscaler = true
  enable_bottlerocket_update_operator = true
  enable_aws_load_balancer_controller = true
  
  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      }
    ]
  }
}
