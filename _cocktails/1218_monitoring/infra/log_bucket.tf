module "s3_bucket_for_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket_prefix = "${var.project_name}-logbucket"

  force_destroy = true
  attach_elb_log_delivery_policy = true
}

output "s3_bucket_for_logs" {
  value = module.s3_bucket_for_logs.s3_bucket_id
}
