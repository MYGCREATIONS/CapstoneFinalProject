output "web_sg_id" {
  description = "Web security group ID."
  value       = aws_security_group.web_sg.id
}
