resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  dynamic "route" {
    for_each = var.route_type == "public" ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = var.gateway_id
    }
  }

  dynamic "route" {
    for_each = var.route_type == "private" ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.nat_gateway_id
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_route_table_association" "this" {
  for_each = {
    for idx, subnet_id in var.subnet_ids : idx => subnet_id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.this.id
}

output "route_table_id" {
  value = aws_route_table.this.id
}
