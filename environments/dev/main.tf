##########################################
# Get Snowflake creds from AWS Secrets Manager
##########################################
data "aws_secretsmanager_secret_version" "snowflake" {
  secret_id = var.snowflake_secret_arn
}

locals {
  snow = jsondecode(data.aws_secretsmanager_secret_version.snowflake.secret_string)
}

######################################
# Modules
######################################

# Infrastructure: creates database, and schemas
module "infrastructure" {
  source      = "../../modules/infrastructure"
  environment = var.environment
  db_base_name = var.db_base_name
}

# Tables: build tables inside the DB created by Infrastructure
module "tables" {
  source        = "../../modules/tables"
  database_name = module.infrastructure.database_name
  environment   = var.environment

  depends_on = [module.infrastructure]
}

# Pipelines: build stages, tasks, procs, etc.
module "pipelines" {
  source = "../../modules/pipelines"

  environment                 = var.environment
  database_name               = module.infrastructure.database_name
  warehouse                   = local.snow.warehouse      # value from secret, also exported as SNOWFLAKE_WAREHOUSE
  snowflake_admin_role        = local.snow.role
  snowflake_aws_principal_arn = var.snowflake_aws_principal_arn
  snowflake_external_id       = var.snowflake_external_id

  pipelines = var.pipelines

  alerts = {
    enabled          = true
    email_recipients = var.alert_emails
  }

  depends_on = [module.tables]
}
