data "aws_ssm_parameter" "bottlerocket_ecs" {
  name = "/aws/service/bottlerocket/aws-ecs-2/x86_64/latest/image_id"
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"

  name = "${var.project_name}-node"

  image_id      = data.aws_ssm_parameter.bottlerocket_ecs.value
  instance_type = "t3.small"

  security_groups                 = [module.autoscaling_sg.security_group_id]
  user_data                       = base64encode(<<-EOT
    [settings.ecs]
    cluster = "${var.project_name}-cluster"
    enable-spot-instance-draining = true
    enable-container-metadata = true
  EOT
  )

  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name = "${var.project_name}-role-node"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 32
  desired_capacity    = 1

  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 20
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
  }

  protect_from_scale_in = true

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { Project = "project" }
    }
  ]
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "${var.project_name}-sg-node"
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]
}
