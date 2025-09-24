

resource "snowflake_view" "this" {
  for_each = var.views

  database   = var.database_name

  schema     = each.value.schema
  name       = each.value.name
  is_secure  = lookup(each.value, "is_secure", true)

  statement = file(each.value.query)
}