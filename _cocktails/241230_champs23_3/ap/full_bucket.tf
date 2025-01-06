module "bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket_prefix = "${var.project_name}-logbucket"

  attach_elb_log_delivery_policy = true

  force_destroy = true
  versioning = {
    enabled = true
  }
  
  lifecycle_rule = [
    {
      id = "garbage_collector"
      enabled = true
      abort_incomplete_multipart_upload_days = 1

      noncurrent_version_expiration = {
        days = 14
      }
    }
  ]

  attach_deny_insecure_transport_policy = true
}

resource "aws_kms_key" "bucket" {}
