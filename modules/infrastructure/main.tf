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

# Create the schemas
resource "snowflake_schema" "schemas" {
  for_each = local.schema_names
  database = snowflake_database.database.name
  name     = each.key
  comment  = "Managed by Terraform"
  depends_on = [ snowflake_database.database ]
}


# Create resource monitors for warehouses
resource "snowflake_resource_monitor" "resource_limits" {
  for_each = var.warehouses
  name = "${upper(each.key)}_${var.environment}_LIMIT"
  credit_quota = each.value.credit_limit.credit_quota
  frequency  = each.value.credit_limit.frequency
}

# Create the warehouses
resource "snowflake_warehouse" "this" {
  for_each = var.warehouses

  name                        = upper(each.key)
  warehouse_size               = each.value.size
  auto_suspend                 = each.value.auto_suspend
  auto_resume                  = each.value.auto_resume
  initially_suspended          = each.value.initially_suspended
  max_cluster_count            = each.value.max_cluster_count
  min_cluster_count            = each.value.min_cluster_count
  scaling_policy               = each.value.scaling_policy
  comment                      = each.value.comment
  enable_query_acceleration    = each.value.enable_query_acceleration
  query_acceleration_max_scale_factor = each.value.query_acceleration_max_scale_factor

  resource_monitor = snowflake_resource_monitor.resource_limits[each.key].name

  depends_on = [ snowflake_resource_monitor.resource_limits ]
}



