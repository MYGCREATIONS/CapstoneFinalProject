output "instance_public_ip" {
  description = "Public IP of the instance."
  value       = aws_instance.web.public_ip
}

output "wordpress_url" {
  description = "HTTP URL for WordPress."
  value       = "http://${aws_instance.web.public_ip}"
}
