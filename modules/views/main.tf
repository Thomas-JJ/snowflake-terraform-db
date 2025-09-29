

resource "snowflake_view" "this" {
  for_each = var.views

  database   = var.database_name

  schema     = each.value.schema
  name       = each.value.name
  is_secure  = each.value.is_secure

  statement = file(each.value.query)
}