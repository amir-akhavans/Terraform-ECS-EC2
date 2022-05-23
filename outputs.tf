output "IP" {
  description = "Contains the EIP allocation ID"
  value       = aws_eip.eip.id
}

output "RDS-Endpoint" {
  value = aws_db_instance.db_instance.endpoint
}

output "instance_arn" {
  value     = aws_instance.instance.arn
  sensitive = false
}
output "instance_private_dns" {
  value     = aws_instance.instance.private_dns
  sensitive = false
}
output "instance_public_dns" {
  value     = aws_instance.instance.public_dns
  sensitive = false
}
output "instance_public_ip" {
  value     = aws_instance.instance.public_ip
  sensitive = false
}
