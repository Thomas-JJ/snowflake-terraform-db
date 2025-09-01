# Create the database
resource "snowflake_database" "database" {
  name    = "${upper(var.db_base_name)}_${upper(var.environment)}"
  comment = "Analytics database for ${var.environment}"
}

# Create a NEW schema instead of PUBLIC
resource "snowflake_schema" "sales" {
  database = snowflake_database.database.name
  name     = "SALES"
  comment  = "Schema for sales tables"
}


