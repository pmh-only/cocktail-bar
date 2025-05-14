module "irsa_cloudwatchagent" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.project_name}-role-cloudwatchagent"

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "amazon-cloudwatch:cloudwatch-agent"
      ]
    }
  }
}

module "irsa_argocd_updater" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.project_name}-role-argocd-updater"

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "argocd:argocd-image-updater"
      ]
    }
  }
}

module "irsa_dynamodb" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.project_name}-role-dynamodb"

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  }

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "dev:dynamodb"
      ]
    }
  }
}

module "irsa_secretsmanager" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.project_name}-role-secretsmanager"

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  }

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "dev:secretsmanager"
      ]
    }
  }
}

# resource "aws_iam_policy" "secretsmanager" {
#   name = "${var.project_name}-policy-secretsmanager"
#   policy = data.aws_iam_policy_document.secretsmanager.json  
# }

# data "aws_iam_policy_document" "secretsmanager" {
#   statement {
#     actions = [
#       "secretsmanager:*"
#     ]

#     resources = ["*"]
#   }
# }

# module "irsa_secretsmanager" {
#   source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   role_name = "${var.project_name}-role-secretsmanager"

#   role_policy_arns = {
#     policy = aws_iam_policy.secretsmanager.arn
#   }

#   oidc_providers = {
#     cluster-oidc-provider = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = [
#         "default:secretsmanager"
#       ]
#     }
#   }
# }

# resource "aws_iam_policy" "fluentd" {
#   name = "project-policy-fluentd"
#   policy = data.aws_iam_policy_document.fluentd.json  
# }

# data "aws_iam_policy_document" "fluentd" {
#   statement {
#     actions = [
#       "logs:PutLogEvents",
#       "logs:CreateLogGroup",
#       "logs:PutRetentionPolicy",
#       "logs:CreateLogStream",
#       "logs:DescribeLogGroups",
#       "logs:DescribeLogStreams"
#     ]

#     resources = ["*"]
#   }
# }

# module "irsa" {
#   source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   role_name = "${var.project_name}-role-fluentd"

#   role_policy_arns = {
#     policy = aws_iam_policy.fluentd.arn
#   }

#   oidc_providers = {
#     cluster-oidc-provider = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = [
#         "default:fluentd"
#       ]
#     }
#   }
# }

# resource "aws_iam_policy" "prometheus" {
#   name = "project-policy-prometheus"
#   policy = data.aws_iam_policy_document.prometheus.json  
# }

# data "aws_iam_policy_document" "prometheus" {
#   statement {
#     actions = [
#       "aps:RemoteWrite", 
#       "aps:GetSeries", 
#       "aps:GetLabels",
#       "aps:GetMetricMetadata"
#     ]

#     resources = ["*"]
#   }
# }

# module "irsa2" {
#   source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   role_name = "${var.project_name}-role-prometheus"

#   role_policy_arns = {
#     policy = aws_iam_policy.prometheus.arn
#   }

#   oidc_providers = {
#     cluster-oidc-provider = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = [
#         "opentelemetry-operator-system:adot-col-prom-metrics",
#         "prometheus:amp-iamproxy-ingest-service-account"
#       ]
#     }
#   }
# }
