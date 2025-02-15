module "log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  # !! IMPORTANT -- DEFAULT IS PREFIX
  bucket_prefix = "${var.project_name}-log"

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
      id                                     = "garbage_collector"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 1

      noncurrent_version_expiration = {
        days = 14
      }
    }
  ]

  attach_deny_insecure_transport_policy = true
  attach_elb_log_delivery_policy        = true
}

resource "aws_s3_bucket_logging" "logging4logbucket" {
  target_bucket = module.log_bucket.s3_bucket_id
  bucket        = module.log_bucket.s3_bucket_id

  target_prefix = ""
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

resource "aws_kms_key" "bucket_log" {}

output "log_bucket" {
  value = module.log_bucket.s3_bucket_id
}

