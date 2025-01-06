module "ec2_client_vpn" {
  source = "cloudposse/ec2-client-vpn/aws"
  name   = "${var.project_name}-vpn"

  vpc_id             = module.vpc.vpc_id
  client_cidr        = "10.254.0.0/16"
  organization_name  = "${var.project_name}-org"
  associated_subnets = module.vpc.private_subnets

  logging_enabled     = true
  logging_stream_name = "${var.project_name}-clientvpn"
  split_tunnel        = true

  authorization_rules = [
    {
      authorize_all_groups = true
      target_network_cidr  = module.vpc.vpc_cidr_block
      description          = "Authorized VPC Range"
    }
  ]

  export_client_certificate = true
}

resource "local_sensitive_file" "client_configuration" {
  filename = "./temp/vpn.ovpn"
  content  = module.ec2_client_vpn.full_client_configuration
}
