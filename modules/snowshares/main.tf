# 1. Create a share
resource "snowflake_share" "this" {
  for_each = var.shares

  name    = upper(each.key)
  comment = "Secure data share for ${each.key}"

  # You can list multiple consumer accounts here if needed
  accounts = each.value.consumer_accounts
}

# 2. Grant schema usage to the share
resource "snowflake_grant_privileges_to_share" "schema_usage" {
  for_each = var.shares

  privileges = ["USAGE"]
  to_share   = snowflake_share.this[each.key].name

  on_schema = "${var.database_name}.${each.value.schema}"
}

# 3. Grant SELECT on all views in the schema
resource "snowflake_grant_privileges_to_share" "views_select" {
  for_each = var.shares

  privileges = ["SELECT"]
  to_share   = snowflake_share.this[each.key].name

  on_schema = "${var.database_name}.${each.value.schema}"
}

