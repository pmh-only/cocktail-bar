locals {
  bastion_sg_name       = "${var.project_name}-sg-bastion"
  bastion_key_name      = "${var.project_name}-keypair"
  bastion_role_name     = "${var.project_name}-role-bastion"
  bastion_instance_name = "${var.project_name}-bastion"
  bastion_ip_name       = "${var.project_name}-bastion"

  keypair_file_path = "./temp/keypair.pem"
  ssh_port          = 2222

  ingress_port_from_my_ip = true
  ingress_ports = [
    { port = local.ssh_port, protocol = "tcp" }
  ]

  egress_ports = [
    { port = 80, protocol = "tcp" },
    { port = 443, protocol = "tcp" }
  ]

  iam_policies = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  bastion_instance_type = "t3.small"

  ami_architecture = "x86_64" # Possible values: "arm64", "x86_64"
  ami_os           = "al2"    # Possible values: "al2023", "al2"
}

locals {
  ami_ssm_pattern = {
    al2023 = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-${local.ami_architecture}",
    al2    = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-${local.ami_architecture}-gp2"
  }
}

data "aws_ssm_parameter" "bastion_ami" {
  name = local.ami_ssm_pattern[local.ami_os]
}

resource "aws_security_group" "bastion" {
  name   = local.bastion_sg_name
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = local.ingress_ports
    content {
      protocol    = ingress.value.protocol
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      cidr_blocks = local.ingress_port_from_my_ip ? ["${chomp(data.http.myip.response_body)}/32"] : ["0.0.0.0/0"]
    }
  }

  dynamic "egress" {
    for_each = local.egress_ports
    content {
      protocol    = egress.value.protocol
      from_port   = egress.value.port
      to_port     = egress.value.port
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = local.bastion_key_name
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keypair" {
  content  = tls_private_key.rsa.private_key_pem
  filename = local.keypair_file_path
}

resource "aws_iam_role" "bastion" {
  name = local.bastion_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_policies" {
  for_each   = toset(local.iam_policies)
  role       = aws_iam_role.bastion.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "bastion" {
  name = local.bastion_role_name
  role = aws_iam_role.bastion.name
}

resource "aws_instance" "bastion" {
  subnet_id            = module.vpc.public_subnets[0]
  security_groups      = [aws_security_group.bastion.id]
  ami                  = data.aws_ssm_parameter.bastion_ami.value
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  key_name             = aws_key_pair.keypair.key_name
  instance_type        = local.bastion_instance_type
  tags                 = { Name = local.bastion_instance_name }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  user_data = <<-EOT
    #!/bin/bash
    echo "Port ${local.ssh_port}" >> /etc/ssh/sshd_config
    systemctl restart sshd
  EOT

  lifecycle {
    ignore_changes = [security_groups]
  }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  tags = {
    Name = local.bastion_ip_name
  }
}

output "bastion_details" {
  value = {
    ip_address        = aws_eip.bastion.public_ip
    instance_id       = aws_instance.bastion.id
    availability_zone = aws_instance.bastion.availability_zone
  }
}

resource "aws_ebs_encryption_by_default" "default" {
  enabled = true
}
