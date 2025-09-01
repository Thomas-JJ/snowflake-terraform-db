
# Outputs
output "database_name" {
  description = "Name of the created database"
  value       = snowflake_database.database.name
}

output "warehouse_name" {
  description = "Name of the warehouse"
  value       = "COMPUTE_WH"
}