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


  # Use formatdate to ensure correct format
  current_timestamp = formatdate("YYYY-MM-DD hh:mm", timeadd(timestamp(), "1m"))

}


# Create resource monitors for warehouses
resource "snowflake_resource_monitor" "resource_limits" {
  for_each = var.warehouses
  name = "${upper(each.key)}_${var.environment}_LIMIT"
  credit_quota = each.value.credit_limit.credit_quota
  frequency  = each.value.credit_limit.frequency
  start_timestamp = local.current_timestamp

}

# Create the warehouses
resource "snowflake_warehouse" "this" {
  for_each = var.warehouses

  name                        = upper(each.key)
  warehouse_size               = each.value.size
  auto_suspend                 = each.value.auto_suspend
  auto_resume                  = each.value.auto_resume
  initially_suspended          = each.value.initially_suspended
  
  comment                      = each.value.comment

  resource_monitor = snowflake_resource_monitor.resource_limits[each.key].name

  depends_on = [ snowflake_resource_monitor.resource_limits ]
}



# Create the database
resource "snowflake_database" "database" {
  name    = "${upper(var.db_base_name)}_${upper(var.environment)}"
  comment = "Analytics database for ${var.environment}"
}

# Create the schemas
resource "snowflake_schema" "schemas" {
  for_each = local.schema_names
  database = snowflake_database.database.name
  name     = each.key
  comment  = "Managed by Terraform"
  depends_on = [ snowflake_database.database ]
}



