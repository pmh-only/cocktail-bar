locals {
  enable_argocd = false
}

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
      configuration_values = jsonencode({
        env = {
          # ENABLE_POD_ENI                    = "true"
          # POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
      })
    }
    kube-proxy = {
      most_recent = true
    }
    amazon-cloudwatch-observability = {
      most_recent              = true
      service_account_role_arn = module.irsa_cloudwatchagent.iam_role_arn
      configuration_values = jsonencode({
        containerLogs = { enabled = false }
      })
    }
  }

  enable_argocd                       = local.enable_argocd
  enable_kube_prometheus_stack        = false
  enable_aws_gateway_api_controller   = false
  enable_karpenter                    = true
  enable_cert_manager                 = true
  enable_metrics_server               = true
  enable_cluster_autoscaler           = true
  enable_aws_load_balancer_controller = true
  enable_external_secrets             = true
  enable_aws_for_fluentbit            = true
  enable_fargate_fluentbit            = true

  kube_prometheus_stack = {
    values = [<<-EOF
      prometheus:
        prometheusSpec:
          scrapeInterval: "5s"
          evaluationInterval: "5s"
    EOF
    ]
  }

  fargate_fluentbit_cw_log_group = {
    name            = "/aws/eks/${module.eks.cluster_name}/fargate"
    use_name_prefix = false
  }

  fargate_fluentbit = {
    flb_log_cw = true
  }

  argocd = {
    values = [<<-EOF
      configs:
        cm:
          timeout.reconciliation: 10s
    EOF
    ]
  }

  aws_load_balancer_controller = {
    values = [<<-EOF
      vpcId: ${aws_vpc.this.id}
    EOF
    ]
  }

  aws_for_fluentbit_cw_log_group = {
    create = false
  }

  aws_for_fluentbit = {
    enable_containerinsights = true
    kubelet_monitoring       = true

    values = [<<-EOF
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      cloudWatchLogs:
        autoCreateGroup: true

      tolerations:
        - operator: Exists
    EOF
    ]

    role_policies = {
      CloudWatchFullAccess = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
    }
  }

  helm_releases = {
    calico = {
      repository = "https://docs.tigera.io/calico/charts"
      chart      = "tigera-operator"
      name       = "calico"

      create_namespace = true
      namespace        = "tigera-operator"

      values = [<<-EOF
          installation:
            kubernetesProvider: EKS
            cni:
              type: AmazonVPC
            calicoNetwork:
              bgp: Disabled
        EOF
      ]
    }
    descheduler = {
      repository = "https://kubernetes-sigs.github.io/descheduler"
      chart      = "descheduler"

      name      = "descheduler"
      namespace = "kube-system"

      values = [<<-EOF
          kind: Deployment
          schedule: "* * * * *"
        EOF
      ]
    }
    # kyverno = {
    #   repository = "https://kyverno.github.io/kyverno"
    #   chart      = "kyverno"
    #   name       = "kyverno"

    #   create_namespace = true
    #   namespace        = "kyverno"

    #   values = [<<-EOF
    #     admissionController:
    #       replicas: 2
    #     backgroundController:
    #       replicas: 2
    #     cleanupController:
    #       replicas: 2
    #     reportsController:
    #       replicas: 2
    #     EOF
    #   ]
    # }
  }
}

data "http" "argocd_image_updater" {
  url = "https://raw.githubusercontent.com/pmh-only/cocktail-bar/refs/heads/main/kubernetes/argocd/image-updater.yml"
}

locals {
  argocd_image_updater = {
    for idx, manifest in split("\n---\n", data.http.argocd_image_updater.response_body)
    : idx => manifest
    if local.enable_argocd
  }
}

resource "kubectl_manifest" "argocd_image_updater" {
  for_each   = local.argocd_image_updater
  depends_on = [module.eks_blueprints_addons]

  yaml_body = replace(
    replace(
      replace(
        each.value,
        "{account_id}",
        data.aws_caller_identity.caller.account_id
      ),
      "{irsa}",
      module.irsa_argocd_updater.iam_role_arn
    ),
    "{region}",
    var.region
  )
}

output "node_iam_role_arn" {
  value = module.eks_blueprints_addons.karpenter.node_iam_role_arn
}
