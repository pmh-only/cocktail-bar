module "bucket_logbucket_logbucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket_prefix = "${var.project_name}-log4logbucket"

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

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.bucket.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  

  attach_deny_insecure_transport_policy = true
}

resource "aws_kms_key" "bucket" {}
