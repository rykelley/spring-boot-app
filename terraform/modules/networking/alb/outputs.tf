
output "alb_dns_name" {
  value       = "aws_lb.example.dns_name"
  description = "The domain name of the load balancer"
}

output "alb_http_listener_arn" {
  value       = aws_alb_listener.http.arn
  description = "The ARN of the http listner"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  Description = " the ALB security group ID"
}
