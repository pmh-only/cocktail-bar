module "s3_bucket_for_logs" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  bucket_prefix = "${var.project_name}-logbucket"

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
