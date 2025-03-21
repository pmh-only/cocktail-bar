locals {
  ecs_ami_arch = "arm64"        # arm64 or x86_64
  ecs_ami_os   = "bottlerocket" # bottlerocket or al2023
}

module "autoscaling" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "${var.project_name}-node"

  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t4g.micro"

  update_default_version = true

  security_groups = [module.autoscaling_sg.security_group_id]
  user_data       = base64encode(local.ecs_userscript)

  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name               = "${var.project_name}-role-node"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = [for subnet in local.ecs_cluster_subnets : aws_subnet.this[subnet.key].id]

  health_check_type = "EC2"
  min_size          = 2
  max_size          = 32
  desired_capacity  = 2

  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # use_mixed_instances_policy = true
  # mixed_instances_policy = {
  #   instances_distribution = {
  #     on_demand_base_capacity                  = 0
  #     on_demand_percentage_above_base_capacity = 20
  #     spot_allocation_strategy                 = "price-capacity-optimized"
  #   }
  # }

  protect_from_scale_in = true

  metadata_options = {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags = {
        Name    = "${var.project_name}-node"
        Project = var.project_name
      }
    }
  ]
}

locals {
  ecs_ami_name = {
    "x86_64:al2023" = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
    "arm64:al2023"  = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"

    "x86_64:bottlerocket" = "/aws/service/bottlerocket/aws-ecs-2/x86_64/latest/image_id"
    "arm64:bottlerocket"  = "/aws/service/bottlerocket/aws-ecs-2/arm64/latest/image_id"
  }["${local.ecs_ami_arch}:${local.ecs_ami_os}"]

  ecs_userscript = {
    "al2023"       = <<-EOT
      #!/bin/bash
      echo 'ECS_CLUSTER=${local.ecs_cluster_name}' >> /etc/ecs/ecs.config
      echo 'ECS_ENABLE_CONTAINER_METADATA=true' >> /etc/ecs/ecs.config
      echo 'ECS_ENABLE_SPOT_INSTANCE_DRAINING=true' >> /etc/ecs/ecs.config
      echo 'ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs","fluentd","none"]' >> /etc/ecs/ecs.config
    EOT
    "bottlerocket" = <<-EOT
      [settings.ecs]
      cluster = "${local.ecs_cluster_name}"
      enable-spot-instance-draining = true
      enable-container-metadata = true
      logging-drivers = ["json-file","awslogs","fluentd","none"]
    EOT
  }[local.ecs_ami_os]
}

data "aws_ssm_parameter" "ecs_ami" {
  name = local.ecs_ami_name
}

module "autoscaling_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "${var.project_name}-sg-node"
  vpc_id = aws_vpc.this.id

  egress_rules = ["all-all"]
}
