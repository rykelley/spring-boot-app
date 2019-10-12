output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

output "instance_security_group_id" {
  value       = aws_security_group.instance.id
  description = "the ID of the EC2 instance security"
}
