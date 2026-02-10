output "rds_endpoint" {
  description = "RDS instance endpoint (host:port)."
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS instance hostname (for wp-config DB_HOST)."
  value       = aws_db_instance.main.address
}
