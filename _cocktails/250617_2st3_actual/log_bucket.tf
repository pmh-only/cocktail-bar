module "log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  # !! IMPORTANT -- DEFAULT IS PREFIX
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
  attach_lb_log_delivery_policy         = true
}

output "log_bucket" {
  value = module.log_bucket.s3_bucket_id
}
