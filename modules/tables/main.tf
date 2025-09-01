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
