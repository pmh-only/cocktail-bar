module "s3_bucket_for_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "${var.project_name}-alb-log-"
  force_destroy = true

  lifecycle_rule = [{
    id = "log"
    enabled = true

    transition = [{
      days          = 30
      storage_class = "ONEZONE_IA"
    }]
  }]

  attach_elb_log_delivery_policy = true  # Required for ALB logs
  attach_lb_log_delivery_policy  = true  # Required for ALB/NLB logs
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy = true
}

resource "aws_s3_object" "access_log" {
  bucket = module.s3_bucket_for_logs.s3_bucket_id
  key = "access_log/"
}

resource "aws_s3_object" "connection_log" {
  bucket = module.s3_bucket_for_logs.s3_bucket_id
  key = "connection_log/"
}

resource "aws_s3_object" "results" {
  bucket = module.s3_bucket_for_logs.s3_bucket_id
  key = "results/"
}
