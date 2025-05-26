output "aws_lb_public_dns" {
  value = aws_lb.app.dns_name
}

output "opensearch_host" {
  value = aws_opensearch_domain.notes.endpoint
}

output "postgres_host" {
  value = aws_db_instance.postgres.address
}

