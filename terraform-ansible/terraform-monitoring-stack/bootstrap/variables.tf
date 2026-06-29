variable "backend_bucket_name" {
  description = "S3 bucket name for Terraform backend state"
  type        = string
  default     = "anurag-monitoring-tfstate-ap-south-1"
}

variable "backend_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-lock-table"
}
