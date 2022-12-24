data "aws_caller_identity" "current" {}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "terraform-s3-${data.aws_caller_identity.current.account_id}"
  acl    = "private"
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  versioning = {
    enabled = true
  }
  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "log/"
  }
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
module "log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = "logs-${data.aws_caller_identity.current.account_id}"
  acl           = "log-delivery-write"
  force_destroy = true

  attach_elb_log_delivery_policy        = true
  attach_lb_log_delivery_policy         = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_kms_key" "s3" {
  description             = "KMS key is used to encrypt bucket objects"
  deletion_window_in_days = 7
  enable_key_rotation = true
}