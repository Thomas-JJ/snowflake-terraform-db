##########################################
# Get Snowflake creds from AWS Secrets Manager
##########################################
#data "aws_secretsmanager_secret_version" "snowflake" {
#  secret_id = var.snowflake_secret_arn
#}

#locals {
#  snow = jsondecode(data.aws_secretsmanager_secret_version.snowflake.secret_string)
#}

######################################
# Modules
######################################

# Infrastructure: creates database, and schemas
module "infrastructure" {
  source      = "../../modules/infrastructure"
  environment = var.environment
  db_base_name = var.db_base_name
  schemas = var.schemas
}

# Tables: build tables inside the DB created by Infrastructure
module "tables" {
  source        = "../../modules/tables"
  database_name = module.infrastructure.database_name
  environment   = var.environment

  audit_columns =  var.audit_columns

  tables = var.tables

  depends_on = [module.infrastructure]
}



# Pipelines: build stages, tasks, procs, etc.
module "pipelines" {
  source = "../../modules/pipelines"

  environment                 = var.environment
  database_name               = module.infrastructure.database_name
  warehouse                   = var.snowflake_warehouse
  snowflake_admin_role        = var.snowflake_role
  snowflake_aws_principal_arn = var.snowflake_aws_principal_arn
  snowflake_external_id       = var.snowflake_external_id

  pipelines = var.pipelines

  alerts = {
    enabled          = true
    email_recipients = var.alert_emails
  }

  depends_on = [module.tables]
}

module "dynamic_tables" {
  source = "../../modules/dynamictables"
  database_name = module.infrastructure.database_name
  dynamic_tables = var.dynamic_tables
  depends_on = [module.tables]
}


module "views" {
  source = "../../modules/views"
  database_name = module.infrastructure.database_name
  views = var.views
  depends_on = [module.tables]
}

#module "shares" {
 # source = "../../modules/snowshares"
 # database_name = module.infrastructure.database_name
#  shares = var.shares
#  depends_on = [module.tables]
#}

module "forecasts" {
  source = "../../modules/forecasts"
  environment =  var.environment
  database_name = module.infrastructure.database_name
  forecasts = var.forecasts
  depends_on = [module.views]
}
