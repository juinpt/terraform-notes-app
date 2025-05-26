output "aws_lb_public_dns" {
  value = aws_lb.front-end.dns_name
}

output "opensearch_host" {
  value = aws_opensearch_domain.es.endpoint
}

output "postgres_host" {
  value = aws_db_instance.postgres.address
}

