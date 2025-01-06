variable "project_name" {
  default = "us-wsi"
}

variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = var.project_name
    }
  }
}

provider "aws" {
  region = "us-east-1"

  alias = "us-east-1"
}

data "http" "myip" {
  url = "https://myip.wtf/text"
}

data "aws_caller_identity" "caller" {

}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.us-east-1
}
