resource "aws_s3_bucket" "terraform_backend" {
  bucket = var.backend_bucket_name

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "terraform-backend-bucket"
    Owner       = "Anurag Maurya"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

locals {
  backend_bucket_id = aws_s3_bucket.terraform_backend.id
}

# Enable Versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = local.backend_bucket_id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "backend_block" {
  bucket = local.backend_bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ownership Controls
resource "aws_s3_bucket_ownership_controls" "backend_ownership" {
  bucket = local.backend_bucket_id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "backend_encryption" {
  bucket = local.backend_bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "backend_lifecycle" {
  bucket = local.backend_bucket_id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}