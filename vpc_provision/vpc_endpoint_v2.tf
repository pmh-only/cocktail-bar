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
    # "rds",
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

  vpc_id                     = aws_vpc.this.id
  create_security_group      = true
  security_group_name        = "${var.project_name}-sg-endpoints"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      protocol    = "tcp"
      from_port   = "443"
      to_port     = "443"
      cidr_blocks = [aws_vpc.this.cidr_block]
    }
  }

  endpoints = merge(
    { for gateway in local.enabled_gateway_endpoints : gateway => {
      service         = gateway
      service_type    = "Gateway"
      route_table_ids = values(aws_route_table.this)[*].id
      tags            = { Name = "${var.project_name}-endpoint-${gateway}" }
      }
    },
    { for interface in local.enabled_interface_endpoints : interface => {
      service             = interface
      private_dns_enabled = true
      subnet_ids          = length(local.intra_subnets_per_az[local.final_azs[0]]) > 0 ? [for az in local.final_azs : aws_subnet.this[local.intra_subnets_per_az[az][0].key].id] : [for az in local.final_azs : aws_subnet.this[local.private_subnets_per_az[az][0].key].id]
      tags                = { Name = "${var.project_name}-endpoint-${interface}" }
      }
    }
  )
}
