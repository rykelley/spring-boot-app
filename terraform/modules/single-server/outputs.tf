output "id" {
  value = aws_instance.instance.id
}

output "name" {
  value = var.name
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}

output "security_group_id" {
  value = aws_security_group.instance.id
}

output "iam_role_id" {
  value = aws_iam_role.instance.id
}

output "instance_ip" {
  value = aws_instance.instance.public_ip
}
