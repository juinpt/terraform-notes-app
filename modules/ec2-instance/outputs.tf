output "aws_instance_public_dns" {
  value = aws_instance.aws_ubuntu[*].public_dns
}

output "instance_ids" {
  value = aws_instance.aws_ubuntu[*].id
}

