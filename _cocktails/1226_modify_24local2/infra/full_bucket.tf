module "bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = "${var.project_name}-frontend-pmhn"

  force_destroy = true
  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.bucket.arn
        sse_algorithm     = "aws:kms"
      }
    }
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

  logging = {
    target_bucket = module.s3_bucket_for_logs.s3_bucket_id
    target_prefix = "s3/"
    target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "EventTime"
      }
    }
  }

  attach_deny_insecure_transport_policy = true
}

resource "aws_kms_key" "bucket" {}
