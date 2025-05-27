output "vpc_subnets_ids" {
  value = data.aws_subnets.default_vpc_subnets.ids
}

output "vpc_cidr_block" {
  value = aws_default_vpc.default.cidr_block
}

output "vpc_id" {
  value = aws_default_vpc.default.id
}
