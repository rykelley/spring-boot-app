output "ecs_cluster_arn" {
  value = aws_ecs_cluster.ecs.id


  depends_on = [aws_autoscaling_group.ecs]
}

output "ecs_cluster_launch_configuration_id" {
  value = aws_launch_configuration.ecs.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs.name


  depends_on = [aws_autoscaling_group.ecs]
}

output "ecs_cluster_asg_name" {
  value = aws_autoscaling_group.ecs.name
}

output "ecs_instance_security_group_id" {
  value = aws_security_group.ecs.id
}

output "ecs_instance_iam_role_arn" {
  value = aws_iam_role.ecs.arn
}

output "ecs_instance_iam_role_name" {

  value = replace(aws_iam_role.ecs.arn, "/.*/+(.*)/", "$1")
}
