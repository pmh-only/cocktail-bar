locals {
  enabled_gateway_endpoints = [
    "s3",
    "dynamodb"
  ]

  enabled_interface_endpoints = [
    "autoscaling",
    "logs",
    "ec2",
    "sts",
    "ssm",
    # "sqs",
    # "sns",
    # "glue",
    "ssmmessages",
    "ec2messages",
    "ecr.api",
    "ecr.dkr",
    "rds",
    # "ecs",
    # "ecs-agent",
    # "ecs-telemetry",
    "secretsmanager",
    # "vpc-lattice",
    # "elasticloadbalancing",
    # "elasticfilesystem"
  ]
}

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id                     = module.vpc.vpc_id
  create_security_group      = true
  security_group_name        = "${var.project_name}-sg-endpoints"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      protocol    = "tcp"
      from_port   = "443"
      to_port     = "443"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = merge(
    { for gateway in local.enabled_gateway_endpoints : gateway => {
      service         = gateway
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags            = { Name = "${var.project_name}-endpoint-${gateway}" }
      }
    },
    { for interface in local.enabled_interface_endpoints : interface => {
      service             = interface
      private_dns_enabled = true
      subnet_ids          = length(module.vpc.intra_subnets) > 0 ? module.vpc.intra_subnets : module.vpc.private_subnets
      tags                = { Name = "${var.project_name}-endpoint-${interface}" }
      }
    }
  )
}
