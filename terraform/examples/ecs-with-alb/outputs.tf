output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_security_group_id" {
  value = module.alb.alb_security_group_id
}

output "http_listener_arns" {
  value = module.alb.http_listener_arns
}
