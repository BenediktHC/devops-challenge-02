output "web_public_ips" {
  value = aws_instance.web[*].public_ip
}

output "db_private_ip" {
    value = aws_instance.db.private_ip
}

output "reverse_proxy_public_ip" {
  value = var.create_reverse_proxy ? aws_instance.reverse_proxy[0].public_ip : null 
}

output "web_instance_id" {
  value = aws_instance.web[0].id
}

output "web_eni_id" {
  value = aws_instance.web[0].primary_network_interface_id
}