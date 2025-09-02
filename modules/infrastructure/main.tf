locals {
  schema_names = toset([
    for s in var.schemas :
    upper(
      replace(
        replace(
          replace(trim(s, " \t\r\n"), "-", "_"),
        " ", "_"),
      ".", "_")
    )
  ])
}



# Create the database
resource "snowflake_database" "database" {
  name    = "${upper(var.db_base_name)}_${upper(var.environment)}"
  comment = "Analytics database for ${var.environment}"
}

resource "snowflake_schema" "schemas" {
  for_each = local.schema_names
  database = snowflake_database.database.name
  name     = each.key
  comment  = "Managed by Terraform"
  depends_on = [ snowflake_database.database ]
}

