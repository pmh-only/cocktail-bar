
module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${var.project_name}-us-cluster"

  # Capacity provider - autoscaling groups
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    worker = {
      auto_scaling_group_arn = module.autoscaling["worker"].autoscaling_group_arn

      managed_scaling = {
        status          = "ENABLED"
        target_capacity = 50
      }
    }
  }
}


module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  for_each = {
    worker = {
      instance_type              = "t3.micro"
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 25
          spot_allocation_strategy                 = "price-capacity-optimized"
        }

        override = [
          {
            instance_type     = "t3.micro"
            weighted_capacity = "1"
          },
        ]
      }
      user_data = <<-EOT
        [settings.ecs]
        cluster = "${var.project_name}-us-cluster"
      EOT
    }
  }

  name = "${var.project_name}-${each.key}"

  image_id      = "ami-0a995e1852db6db8a"
  instance_type = each.value.instance_type

  security_groups                 = [module.autoscaling_sg.security_group_id]
  user_data                       = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name               = "${var.project_name}-role-worker"
  iam_role_description        = "ECS role for worker"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size            = 2
  max_size            = 32
  desired_capacity    = 2

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }
  # Spot instances
  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project_name}-sg-worker"
  description = "Autoscaling group security group"
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]
}
