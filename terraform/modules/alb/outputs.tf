output "alb_name" {
  value = element(
    concat(
      aws_alb.alb_with_logs.*.name,
      aws_alb.alb_without_logs.*.name,
    ),
    0,
  )
}

output "alb_arn" {
  value = element(
    concat(aws_alb.alb_with_logs.*.arn, aws_alb.alb_without_logs.*.arn),
    0,
  )
}

output "alb_dns_name" {
  value = element(
    concat(
      aws_alb.alb_with_logs.*.dns_name,
      aws_alb.alb_without_logs.*.dns_name,
    ),
    0,
  )
}

output "alb_hosted_zone_id" {
  value = element(
    concat(
      aws_alb.alb_with_logs.*.zone_id,
      aws_alb.alb_without_logs.*.zone_id,
    ),
    0,
  )
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "listener_arns" {
  value = merge(
    zipmap(var.http_listener_ports, aws_alb_listener.http.*.arn),
    zipmap(
      data.template_file.https_listener_ports_and_ssl_certs_ports.*.rendered,
      aws_alb_listener.https_non_acm_certs.*.arn,
    ),
    zipmap(
      data.template_file.https_listener_ports_and_acm_ssl_certs_ports.*.rendered,
      aws_alb_listener.https_acm_certs.*.arn,
    ),
  )
}

# Outputs a map whose key is a port on which there exists an ALB HTTP Listener, and whose value is the ARN of that Listener.
output "http_listener_arns" {
  value = zipmap(var.http_listener_ports, aws_alb_listener.http.*.arn)
}
