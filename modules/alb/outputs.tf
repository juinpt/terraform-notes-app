output "fe_lb_dns_name" {
  value = aws_lb.front_end.dns_name
}

output "fe_lb_zone_id" {
  value = aws_lb.front_end.zone_id
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.app.arn
}

