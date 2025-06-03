resource "aws_default_vpc" "default" {
}

# Get all subnets ids in the default VPC
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_default_vpc.default.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.default_vpc_subnets.ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true
  auto_accept         = true

  tags = {
    Name = "secretsmanager-endpoint"
  }
}
