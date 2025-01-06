module "s3_bucket_for_cf_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "${var.project_name}-cf-log-"
  force_destroy = true

  lifecycle_rule = [{
    id      = "log"
    enabled = true

    transition = [{
      days          = 30
      storage_class = "ONEZONE_IA"
    }]
  }]

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
}

resource "aws_s3_object" "standard_log" {
  bucket = module.s3_bucket_for_cf_logs.s3_bucket_id
  key    = "standard_log/"
}
