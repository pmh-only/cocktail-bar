#################################

variable "project_name" {
  default = "project"
}

variable "region" {
  default = "ap-northeast-2"
}

#################################

terraform {
  required_providers {
    awsutils = {
      source = "cloudposse/awsutils"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project = var.project_name
      owner   = "pmh_only"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

provider "awsutils" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

data "http" "myip" {
  url = "https://myip.wtf/text"
}

data "aws_caller_identity" "caller" {

}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.us-east-1
}

# ---

resource "aws_ebs_encryption_by_default" "default" {
  enabled = true
}

resource "aws_s3_account_public_access_block" "default" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
