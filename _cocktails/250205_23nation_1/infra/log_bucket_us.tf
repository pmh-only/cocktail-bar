module "log_bucket_us" {
  providers = {
    aws = aws.us-east-1
  }

  source        = "terraform-aws-modules/s3-bucket/aws"
  bucket_prefix = "${var.project_name}-log"

  force_destroy = true
  versioning = {
    enabled = true
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

resource "aws_s3_bucket_logging" "logging4logbucket_us" {
  provider = aws.us-east-1

  target_bucket = module.log_bucket_us.s3_bucket_id
  bucket        = module.log_bucket_us.s3_bucket_id

  target_prefix = ""
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

output "log_bucket_us" {
  value = module.log_bucket_us.s3_bucket_id
}
