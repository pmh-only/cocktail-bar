resource "aws_iam_policy" "sm" {
  name   = "project-policy-sm"
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

resource "aws_iam_policy" "fluentd" {
  name   = "${var.project_name}-policy-fluentd"
  policy = data.aws_iam_policy_document.fluentd.json
}

data "aws_iam_policy_document" "fluentd" {
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
  role_name = "${var.project_name}-role-fluentd"

  role_policy_arns = {
    policy = aws_iam_policy.fluentd.arn
  }

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "default:fluentd"
      ]
    }
  }
}

resource "aws_iam_policy" "ecr" {
  name   = "${var.project_name}-policy-ecr"
  policy = data.aws_iam_policy_document.ecr.json
}

data "aws_iam_policy_document" "ecr" {
  statement {
    actions = [
      "ecr:*",
      "s3:*"
    ]

    resources = ["*"]
  }
}

module "irsa3" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.project_name}-role-ecr"

  role_policy_arns = {
    policy = aws_iam_policy.ecr.arn
  }

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "default:ecr"
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
