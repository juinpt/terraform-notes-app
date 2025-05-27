resource "aws_default_vpc" "default" {
}

# Get all subnets ids in the default VPC
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}
