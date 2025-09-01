# Tables module outputs

output "table_names" {
  description = "Names of all created tables"
  value = {
    pos_sales_daily = module.possalesdaily_table.table_name
    pos_item_sales_daily   = module.positemsalesdaily_table.table_name
  }
}

output "fully_qualified_names" {
  description = "Fully qualified table names for other modules"
  value = {
    pos_sales_daily = module.possalesdaily_table.fully_qualified_name
    pos_item_sales_daily   = module.positemsalesdaily_table.fully_qualified_name
  }
}
