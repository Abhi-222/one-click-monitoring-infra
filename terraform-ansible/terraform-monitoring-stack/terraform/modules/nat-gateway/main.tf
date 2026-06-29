resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  depends_on = [aws_eip.nat]

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "nat_gateway_id" {
  value = aws_nat_gateway.this.id
}
