output "IP" {
  description = "Contains the EIP allocation ID"
  value       = aws_eip.eip.public_ip
}

output "instance_public_ip" {
  value     = aws_instance.instance.public_ip
  sensitive = false
}
