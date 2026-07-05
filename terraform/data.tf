data "aws_availability_zones" "available" {
  state = "available"
}

# Dynamically fetches the current, verified AL2023 AMI ID directly from AWS
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-x86_64" # or "al2023-ami-kernel-default-x86_64"
}
