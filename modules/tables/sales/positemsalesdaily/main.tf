resource "snowflake_table" "pos_item_sales_daily" {
  database = var.database_name
  schema   = var.schema_name
  name     = "POS_ITEM_SALES_DAILY"
  
  comment = "Item sales data - one row per date/store/daypart/item with quantity > 0"
  
  # Primary dimensions
  column {
    name     = "DATE"
    type     = "DATE"
    nullable = false
    comment  = "Business date for this sales data"
  }
  
  column {
    name     = "STORE_ID"
    type     = "NUMBER(10,0)"
    nullable = false
    comment  = "Store identifier"
  }
  
  column {
    name     = "ITEM_ID"
    type     = "NUMBER(10,0)"
    nullable = false
    comment  = "Item/product identifier"
  }
  
  # Sales metrics (the actual facts)
  column {
    name     = "SALES_AMT"
    type     = "NUMBER(10,2)"
    nullable = false
    comment  = "Total price/revenue for this item"
    default {
      expression = "0.00"
    }
  }
  
  column {
    name     = "SALES_QTY"
    type     = "NUMBER(10,0)"
    nullable = false
    comment  = "Quantity of item sold"
    default {
      expression = "0.00"
    }
  }
  
}

# Primary key constraint
resource "snowflake_table_constraint" "pos_item_sales_daily_pk" {
  table_id = "${var.database_name}.${var.schema_name}.${upper("POS_ITEM_SALES_DAILY")}"
  name     = "PK_POS_ITEM_SALES_DAILY"
  type     = "PRIMARY KEY"
  columns  = ["DATE", "STORE_ID", "ITEM_ID"]
  
  depends_on = [snowflake_table.pos_item_sales_daily]
}



resource "snowflake_table" "stage_pos_item_sales_daily" {
  database = var.database_name
  schema   = var.schema_name
  name     = "STG_POS_ITEM_SALES_DAILY"
  
  comment = "Item sales data - one row per date/store/daypart/item with quantity > 0"
  
  # Primary dimensions
  column {
    name     = "DATE"
    type     = "DATE"
    nullable = false
    comment  = "Business date for this sales data"
  }
  
  column {
    name     = "STORE_ID"
    type     = "NUMBER(10,0)"
    nullable = false
    comment  = "Store identifier"
  }
  
  column {
    name     = "ITEM_ID"
    type     = "NUMBER(10,0)"
    nullable = false
    comment  = "Item/product identifier"
  }
  
  # Sales metrics (the actual facts)
  column {
    name     = "SALES_AMT"
    type     = "NUMBER(10,2)"
    nullable = true
    comment  = "Quantity of items sold"
    default {
      expression = "0.00"
    }
  }
  
  column {
    name     = "SALES_QTY"
    type     = "NUMBER(10,2)"
    nullable = true
    comment  = "Total price/revenue for this item"
    default {
      expression = "0.00"
    }
  }

}

