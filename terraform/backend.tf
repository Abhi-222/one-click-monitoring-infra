terraform {
  backend "s3" {
    bucket       = "monitoring-stack-dev-state-yogesh"
    key          = "terraform/monitoring-stack/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
