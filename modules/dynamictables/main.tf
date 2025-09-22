
resource "snowflake_dynamic_table" "this" {
  for_each = var.dynamic_tables

  database  = var.database_name
  
  schema    = each.value.schema_name
  name      = each.value.table_name
  warehouse = each.value.warehouse

  query = file(each.value.query)

  dynamic "target_lag" {
    for_each = [each.value.target_lag]
    content {
      # When DOWNSTREAM
      downstream = each.value.target_lag == "DOWNSTREAM" ? true : null

      # When interval (like "5 minutes")
      maximum_duration = each.value.target_lag != "DOWNSTREAM" ? each.value.target_lag : null
    }
  }
  # Optional attributes
  comment      = try(each.value.comment, null)
  initialize = coalesce(try(each.value.initialize, null), "ON_SCHEDULE")
}