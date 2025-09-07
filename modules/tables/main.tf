locals {
  # business/base columns per table
  base_columns_by_table = {
    for tkey, t in var.tables :
    tkey => [
      for f in t.fields : {
        name          = f.field_name
        type          = f.data_type
        nullable      = f.nullable
        default_value = try(f.default_value, null)
        comment       = try(f.comment, null)
      }
    ]
  }

  # uppercase names for quick de-dupe
  base_names_uc_by_table = {
    for tkey, t in var.tables :
    tkey => [for f in t.fields : upper(f.field_name)]
  }

  # audit columns as a list (keeps the exact order from var.audit_columns)
  audit_cols_list = [
    for a in var.audit_columns : {
      name          = a.field_name
      type          = a.data_type
      nullable      = a.nullable
      default_value = try(a.default, null)
      comment       = try(a.comment, null)
    }
  ]

  # only add audit columns that aren't already in the table
  audit_to_add_by_table = {
    for tkey, t in var.tables :
    tkey => [
      for a in local.audit_cols_list : a
      if !contains(local.base_names_uc_by_table[tkey], upper(a.name))
    ]
  }

  columns_by_table = {
    for tkey, t in var.tables :
    tkey => concat(
      local.base_columns_by_table[tkey],
      (lookup(t, "add_audit_columns", false) ? local.audit_to_add_by_table[tkey] : [])
    )
  }

  table_defs = {
    for tkey, t in var.tables :
    tkey => {
      name    = t.table_name
      schema  = t.schema_name
      columns = local.columns_by_table[tkey]
      pk_cols = [for f in t.fields : f.field_name if try(f.primary_key, false)]
    }
  }

  stage_table_defs = {
    for tkey, t in var.tables :
    tkey => {
      name    = t.table_name
      schema  = t.schema_name
      columns = local.base_columns_by_table[tkey]
      pk_cols = [for f in t.fields : f.field_name if try(f.primary_key, false)]
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
        for_each = length(try(trimspace(tostring(column.value.default_value)), "")) > 0 ? [1] : []
        content {
          expression = trimspace(tostring(column.value.default_value))
        }
      }
    }
  }
}

resource "snowflake_table" "staging_tables" {
  for_each = local.stage_table_defs

  database = var.database_name
  schema   = each.value.schema
  name     = "STG_${each.value.name}"

  dynamic "column" {
    for_each = each.value.columns
    content {
      name     = column.value.name
      type     = column.value.type
      nullable = column.value.nullable
      comment  = column.value.comment

      dynamic "default" {
        for_each = length(try(trimspace(tostring(column.value.default_value)), "")) > 0 ? [1] : []
        content {
          expression = trimspace(tostring(column.value.default_value))
        }
      }
    }
  }
}