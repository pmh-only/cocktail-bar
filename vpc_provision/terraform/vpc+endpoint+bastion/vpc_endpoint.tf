module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  create_security_group      = true
  security_group_name = "${var.project_name}-sg-endpoints"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }
  

  endpoints = {
    s3 = {
      service = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags                = { Name = "${var.project_name}-endpoint-s3" }
    },
    dynamodb = {
      service = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags                = { Name = "${var.project_name}-endpoint-dynamodb" }
    },
    autoscaling = {
      service    = "autoscaling"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-autoscaling" }
    },
    logs = {
      service    = "logs"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-logs" }
    },
    ec2 = {
      service    = "ec2"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ec2" }
    },
    sts = {
      service    = "sts"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-sts" }
    },
    ssm = {
      service    = "ssm"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ssm" }
    },
    sqs = {
      service    = "sqs"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-sqs" }
    },
    sns = {
      service    = "sns"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-sns" }
    },
    ec2 = {
      service    = "ec2"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ec2" }
    },
    ssmmessages = {
      service    = "ssmmessages"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ssmmessages" }
    },
    ec2messages = {
      service    = "ec2messages"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ec2messages" }
    },
    ecrapi = {
      service    = "ecr.api"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ecr.api" }
    },
    ecrdkr = {
      service    = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ecr.dkr" }
    },
    rds = {
      service    = "rds"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-rds" }
    },
    ecs = {
      service    = "ecs"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ecs" }
    },
    ecsagent = {
      service    = "ecs-agent"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ecsagent" }
    },
    ecstelemetry = {
      service    = "ecs-telemetry"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-ecstelemetry" }
    },
    glue = {
      service    = "glue"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-glue" }
    },
    secretsmanager = {
      service    = "secretsmanager"
      private_dns_enabled = true
      subnet_ids = module.vpc.intra_subnets
      tags       = { Name = "${var.project_name}-endpoint-secretsmanager" }
    }
  }
}
