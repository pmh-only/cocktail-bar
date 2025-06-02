locals {
  enable_argocd = false
  enable_calico = false
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  observability_tag = null

  eks_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        replicaCount = 1
      })
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          # ENABLE_POD_ENI                    = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
          NETWORK_POLICY_ENFORCING_MODE     = "standard"
          # ENABLE_PREFIX_DELEGATION          = "true"
          # WARM_PREFIX_TARGET                = "1"
        }
        enableNetworkPolicy = "true"
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
  enable_karpenter                    = false
  enable_metrics_server               = true
  enable_cluster_autoscaler           = true
  enable_aws_load_balancer_controller = false # <- eks auto
  enable_external_secrets             = false
  enable_aws_for_fluentbit            = true
  enable_fargate_fluentbit            = false

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
      replicaCount: 1
      vpcId: ${aws_vpc.this.id}
    EOF
    ]
  }

  aws_gateway_api_controller = {
    values = [<<-EOF
      clusterVpcId: ${aws_vpc.this.id}
      clusterName: ${module.eks.cluster_name}
      latticeEndpoint: ""
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

  cluster_autoscaler = {
    values = [<<-EOF
      extraArgs:
        scan-interval: 10s
        scale-down-delay-after-add: 1m
        scale-down-delay-after-delete: 0s
        scale-down-delay-after-failure: 1m
        scale-down-unneeded-time: 1m
        node-deletion-delay-timeout: 1m
        node-deletion-batcher-interval: 0s
    EOF
    ]

    set = [{
      name  = "image.tag"
      value = "v1.32.1"
    }]
  }

  helm_releases = {
    # descheduler = {
    #   repository = "https://kubernetes-sigs.github.io/descheduler"
    #   chart      = "descheduler"

    #   name      = "descheduler"
    #   namespace = "kube-system"

    #   values = [<<-EOF
    #       kind: Deployment
    #       schedule: "* * * * *"
    #     EOF
    #   ]
    # }
    # kyverno = {
    #   repository = "https://kyverno.github.io/kyverno"
    #   chart      = "kyverno"
    #   name       = "kyverno"

    #   create_namespace = true
    #   namespace        = "kyverno"

    #   values = [<<-EOF
    #     admissionController:
    #       replicas: 1
    #     backgroundController:
    #       enabled: false
    #     cleanupController:
    #       enabled: false
    #     reportsController:
    #       enabled: false
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


data "http" "calico" {
  url = "https://raw.githubusercontent.com/pmh-only/cocktail-bar/refs/heads/main/kubernetes/calico_install.yml"
}

locals {
  calico = {
    for idx, manifest in split("\n---\n", data.http.calico.response_body)
    : idx => manifest
    if local.enable_calico
  }
}

resource "kubectl_manifest" "calico" {
  for_each   = local.calico
  depends_on = [module.eks_blueprints_addons]

  yaml_body = each.value
}

output "node_iam_role_arn" {
  value = module.eks_blueprints_addons.karpenter.node_iam_role_arn
}
