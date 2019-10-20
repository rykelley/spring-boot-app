output "asg_name" {
  value = aws_autoscaling_group.autoscaling_group.name
}

output "asg_unique_id" {
  value = random_id.asg_id.dec
}
