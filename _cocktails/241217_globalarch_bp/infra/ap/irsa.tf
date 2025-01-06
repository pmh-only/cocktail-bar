resource "aws_iam_policy" "sm" {
  name   = "project-ap-policy-sm"
  policy = data.aws_iam_policy_document.sm.json
}

data "aws_iam_policy_document" "sm" {
  statement {
    actions = [
      "secretsmanager:*"
    ]

    resources = ["*"]
  }
}

module "irsa" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.project_name}-role-sm"

  role_policy_arns = {
    policy = aws_iam_policy.sm.arn
  }

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "default:sm"
      ]
    }
  }
}

resource "aws_iam_policy" "fluentbit" {
  name   = "${var.project_name}-policy-fluentbit"
  policy = data.aws_iam_policy_document.fluentbit.json
}

data "aws_iam_policy_document" "fluentbit" {
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:PutRetentionPolicy",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = ["*"]
  }
}

module "irsa2" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.project_name}-role-fluentbit"

  role_policy_arns = {
    policy = aws_iam_policy.fluentbit.arn
  }

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "default:fluentbit"
      ]
    }
  }
}

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
