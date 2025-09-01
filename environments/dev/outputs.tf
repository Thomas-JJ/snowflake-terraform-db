output "database_info" {
  description = "Database information"
  value = {
    name = module.infrastructure.database_name
  }
}

output "table_info" {
  description = "Created table information"
  value = module.tables.table_names
}

output "environment" {
  description = "Current environment"
  value = var.environment
}
