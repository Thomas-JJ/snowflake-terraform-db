locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "snowflake-tables"
  }
}

module "possalesdaily_table" {
  source = "./sales/possalesdaily"
  
  database_name = var.database_name
  schema_name   = "SALES"
  common_tags   = local.common_tags
}


module "positemsalesdaily_table" {
  source = "./sales/positemsalesdaily"
  
  database_name = var.database_name
  schema_name   = "SALES"
  common_tags   = local.common_tags

}


locals {
  table_defs = {
    for tkey, t in var.tables :
    tkey => {
      name    = t.table_name
      schema  = t.schema_name
      columns = [
        for _, f in t.fields : {
          name          = f.field_name
          type          = f.data_type
          nullable      = f.nullable
          # keep these possibly-null
          default_value = try(f.default_value, null)
          comment       = try(f.comment, null)
        }
      ]
      pk_cols = [for _, f in t.fields : f.field_name if f.primary_key]
    }
  }
}

resource "snowflake_table" "this" {
  for_each = local.table_defs

  database = var.database_name
  schema   = each.value.schema
  name     = each.value.name

  dynamic "column" {
    for_each = each.value.columns
    content {
      name     = column.value.name
      type     = column.value.type
      nullable = column.value.nullable
      comment  = column.value.comment

      dynamic "default" {
        for_each = length(
          try(trimspace(tostring(column.value.default_value)), "")
        ) > 0 ? [1] : []

        content {
          # safe now because for_each only runs when it’s non-empty
          expression = trimspace(tostring(column.value.default_value))
        }
      }

    }
  }
}


