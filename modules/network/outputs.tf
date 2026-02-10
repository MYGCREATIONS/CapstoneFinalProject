output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID."
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID."
  value       = aws_subnet.private.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for RDS subnet group (2 AZs)."
  value       = [aws_subnet.private.id, aws_subnet.private_2.id]
}
