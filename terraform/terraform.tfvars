environment             = "dev"
aws_region              = "ap-south-1"
key_name                = "yogesh-check"
allowed_ssh_cidr        = "0.0.0.0/0"
instance_type           = "t3.micro"
prometheus_port         = 9090
node_exporter_port      = 9100
grafana_port            = 3000
asg_min_size            = 2
asg_desired_capacity    = 2
asg_max_size            = 2
backend_bucket_name     = "monitoring-stack-dev-state-yogesh"
backend_lock_table_name = "monitoring-stack-dev-lock-yogesh"
project_owner           = "Yogesh Singh"


# Add your specific AMI ID here
ami_id = "ami-0d351f1b760a30161"