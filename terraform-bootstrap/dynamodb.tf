# DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.backend_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  table_class  = "STANDARD"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Enable Point-in-Time Recovery
  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "terraform-lock-table"
    Owner       = "Yogesh Singh"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "Monitoring Infrastructure"
  }
}