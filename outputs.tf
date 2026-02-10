output "instance_public_ip" {
  description = "Public IP of the WordPress instance."
  value       = module.compute.instance_public_ip
}

output "wordpress_url" {
  description = "HTTP URL to access WordPress."
  value       = module.compute.wordpress_url
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (host:port)."
  value       = module.rds.rds_endpoint
}
