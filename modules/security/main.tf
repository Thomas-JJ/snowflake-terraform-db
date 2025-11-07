

resource "snowflake_account_role" "roles" {
  for_each = var.role_access

  name    = each.key
  comment = "Terraform-managed role for ${each.key}"
}


#######################################
# Database Usage
#######################################
resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  for_each = var.role_access

  privileges = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = var.database_name
  }

  account_role_name = each.key
  
  depends_on = [ snowflake_account_role.roles ]
}

#######################################
# Schema Usage
#######################################

locals {
  # The 'flatten' function turns a list-of-lists into a single flat list.
  # The outer 'for' iterates through each role.
  # The inner 'for' iterates through each schema within that role.
  role_schema_grants = flatten([
    for role_name, role_data in var.role_access : [
      for schema_name, privs in role_data.schemas : {
        role_name   = role_name
        schema_name = schema_name
        privileges  = privs
        views_only = lookup(role_data, "views_only", true)
      }
    ]
  ])
}


resource "snowflake_grant_privileges_to_account_role" "schema_usage" {
  # Flatten the map-of-maps into a list of role-schema pairs
  for_each = {
    for item in local.role_schema_grants : "${item.role_name}_${item.schema_name}" => item
  }

  privileges = ["USAGE"] #each.value.privileges

  on_schema {

    schema_name = "${var.database_name}.${each.value.schema_name}"
  }

  account_role_name = each.value.role_name

  depends_on = [ snowflake_grant_privileges_to_account_role.database_usage ]
}

############################################
# Table Grants
############################################
resource "snowflake_grant_privileges_to_account_role" "table_access" {
  for_each = {
    for k, v in local.role_schema_grants :
    k => v
    if v.views_only == false
  }
  privileges = ["SELECT"]
  
  on_schema_object {
    all{
      object_type_plural = "TABLES"
      in_schema   = "${var.database_name}.${each.value.schema_name}"
    }
  }
  account_role_name = each.value.role_name
}

resource "snowflake_grant_privileges_to_account_role" "table_access_future" {
  for_each = {
    for k, v in local.role_schema_grants :
    k => v
    if v.views_only == false
  }
  privileges = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "${var.database_name}.${each.value.schema_name}"
    }
  }
  account_role_name = each.value.role_name
}
############################################
# View Grants
############################################
resource "snowflake_grant_privileges_to_account_role" "view_access_current" {
  for_each = {
    for k, v in local.role_schema_grants :
    k => v
  }
  privileges = ["SELECT"]
  
  on_schema_object {
    all{
      object_type_plural = "VIEWS"
      in_schema   = "${var.database_name}.${each.value.schema_name}"
    }
  }
  account_role_name = each.value.role_name
}

resource "snowflake_grant_privileges_to_account_role" "view_access_future" {
  for_each = {
    for k, v in local.role_schema_grants :
    k => v
  }
  privileges = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "${var.database_name}.${each.value.schema_name}"
    }
  }
  account_role_name = each.value.role_name
}




#######################################
# Warehouse Grants
#######################################
locals {
  warehouse_privileges_map = {
    for role_name, role_data in var.role_access :
    role_name => (
      contains(flatten(values(role_data.schemas)), "ALL"
      ) ? ["USAGE", "OPERATE", "MONITOR"] :
      (
        contains(flatten(values(role_data.schemas)), "INSERT") ||
        contains(flatten(values(role_data.schemas)), "UPDATE") ||
        contains(flatten(values(role_data.schemas)), "DELETE")
      ) ? ["USAGE", "OPERATE"] :
      ["USAGE"]
    )
  }
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  for_each = var.role_access

  privileges = local.warehouse_privileges_map[each.key]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = each.value.warehouses
  }

  account_role_name = each.key

  depends_on = [ snowflake_grant_privileges_to_account_role.database_usage ]
}



