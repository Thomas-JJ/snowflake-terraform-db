output "table_name" {
  description = "Name of the possalesdaily table"
  value       = snowflake_table.pos_sales_daily.name
}

output "fully_qualified_name" {
  description = "Fully qualified table name"
  value       = "${var.database_name}.${var.schema_name}.${snowflake_table.pos_sales_daily.name}"
}

output "table_id" {
  description = "Table resource ID for dependencies"
  value       = snowflake_table.pos_sales_daily.id
}
