output "database_info" {
  description = "Database information"
  value = {
    name = module.infrastructure.database_name
  }
}

output "environment" {
  description = "Current environment"
  value = var.environment
}
