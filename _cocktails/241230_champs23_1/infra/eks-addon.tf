module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    amazon-cloudwatch-observability = {
      most_recent              = true
      service_account_role_arn = module.irsa_cloudwatchagent.iam_role_arn
      configuration_values = jsonencode({
        "containerLogs" : { "enabled" : false }
      })
    }
  }

  enable_cert_manager                 = true
  enable_metrics_server               = true
  enable_aws_load_balancer_controller = true
  enable_fargate_fluentbit            = true
  fargate_fluentbit = {
    flb_log_cw = true
  }

  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      }
    ]
  }
}
