module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = var.vpc_cidr
  name     = "${local.env_prefix}-vpc"
  tags     = merge(local.common_tags, { Name = "${local.env_prefix}-vpc" })
}

module "public_subnets" {
  source = "./modules/subnet"
  for_each = {
    public_1 = {
      cidr = var.public_cidr_blocks[0]
      az   = data.aws_availability_zones.available.names[0]
      name = "${local.env_prefix}-public-1"
    }
    public_2 = {
      cidr = var.public_cidr_blocks[1]
      az   = data.aws_availability_zones.available.names[1]
      name = "${local.env_prefix}-public-2"
    }
  }

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  name                    = each.value.name
  tags                    = merge(local.common_tags, { Name = each.value.name })
}

module "private_tool_subnets" {
  source = "./modules/subnet"
  for_each = {
    private_1 = {
      cidr = var.private_tool_cidr_blocks[0]
      az   = data.aws_availability_zones.available.names[0]
      name = "${local.env_prefix}-private-1"
    }
    private_2 = {
      cidr = var.private_tool_cidr_blocks[1]
      az   = data.aws_availability_zones.available.names[1]
      name = "${local.env_prefix}-private-2"
    }
  }

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
  name                    = each.value.name
  tags                    = merge(local.common_tags, { Name = each.value.name })
}

module "internet_gateway" {
  source = "./modules/internet-gateway"

  vpc_id = module.vpc.vpc_id
  name   = "${local.env_prefix}-igw"
  tags   = merge(local.common_tags, { Name = "${local.env_prefix}-igw" })
}

module "nat_gateway" {
  source = "./modules/nat-gateway"

  public_subnet_id = module.public_subnets["public_1"].id
  name             = "${local.env_prefix}-nat"
  tags             = merge(local.common_tags, { Name = "${local.env_prefix}-nat" })
}

module "public_route_table" {
  source = "./modules/route-table"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = [for s in values(module.public_subnets) : s.id]
  route_type = "public"
  gateway_id = module.internet_gateway.igw_id
  name       = "${local.env_prefix}-public-rt"
  tags       = merge(local.common_tags, { Name = "${local.env_prefix}-public-rt" })
}

module "private_route_table" {
  source = "./modules/route-table"

  vpc_id         = module.vpc.vpc_id
  subnet_ids     = [for s in values(module.private_tool_subnets) : s.id]
  route_type     = "private"
  nat_gateway_id = module.nat_gateway.nat_gateway_id
  name           = "${local.env_prefix}-private-rt"
  tags           = merge(local.common_tags, { Name = "${local.env_prefix}-private-rt" })
}

module "security_group" {
  source = "./modules/security-group"

  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  allowed_ssh_cidr   = var.allowed_ssh_cidr
  grafana_port       = var.grafana_port
  prometheus_port    = var.prometheus_port
  node_exporter_port = var.node_exporter_port
  name_bastion       = "${local.env_prefix}-bastion-sg"
  name_alb           = "${local.env_prefix}-alb-sg"
  name_monitoring    = "${local.env_prefix}-monitoring-sg"
  tags               = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix = local.env_prefix
  tags        = local.common_tags
}

module "bastion" {
  source = "./modules/bastion"

  public_subnet_id = module.public_subnets["public_1"].id
  ami_id           = data.aws_ami.amazon_linux.id
  instance_type    = var.instance_type
  key_name         = var.key_name
  bastion_sg_id    = module.security_group.bastion_sg_id
  name             = "${local.env_prefix}-bastion"
  tags             = merge(local.common_tags, { Name = "${local.env_prefix}-bastion" })
}

module "efs" {
  source = "./modules/efs"

  private_subnet_ids = [for s in values(module.private_tool_subnets) : s.id]
  monitoring_sg_id   = module.security_group.monitoring_sg_id
  name               = "${local.env_prefix}-efs"
  tags               = merge(local.common_tags, { Name = "${local.env_prefix}-efs" })
}

module "alb" {
  source = "./modules/alb"

  vpc_id       = module.vpc.vpc_id
  subnet_ids   = [for s in values(module.public_subnets) : s.id]
  alb_sg_id    = module.security_group.alb_sg_id
  grafana_port = var.grafana_port
  name         = "${local.env_prefix}-alb"
  tags         = merge(local.common_tags, { Name = "${local.env_prefix}-alb" })
}

module "launch_template" {
  source = "./modules/launch-template"

  ami_id                    = data.aws_ami.amazon_linux.id
  instance_type             = var.instance_type
  key_name                  = var.key_name
  monitoring_sg_id          = module.security_group.monitoring_sg_id
  instance_profile_name     = module.iam.instance_profile_name
  efs_file_system_id        = module.efs.efs_id
  grafana_port              = var.grafana_port
  node_exporter_port        = var.node_exporter_port
  prometheus_volume_size_gb = var.prometheus_volume_size_gb
  name                      = "${local.env_prefix}-lt"
  name_prefix               = local.env_prefix
  tags                      = merge(local.common_tags, { Name = "${local.env_prefix}-lt" })
}

module "autoscaling" {
  source = "./modules/autoscaling"

  launch_template_id = module.launch_template.launch_template_id
  private_subnet_ids = [for s in values(module.private_tool_subnets) : s.id]
  target_group_arn   = module.alb.target_group_arn
  min_size           = var.asg_min_size
  desired_capacity   = var.asg_desired_capacity
  max_size           = var.asg_max_size
  name               = "${local.env_prefix}-asg"
  environment        = var.environment
  tags               = merge(local.common_tags, { Name = "${local.env_prefix}-asg" })
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  name_prefix = local.env_prefix
  tags        = local.common_tags
}

resource "aws_ssm_parameter" "monitoring_env" {
  name  = "/${var.environment}/monitoring/project"
  type  = "String"
  value = "Monitoring Stack"
  tags  = local.common_tags
}
