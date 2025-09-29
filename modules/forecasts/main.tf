
resource "snowflake_view" "this" {
  for_each = var.forecasts

  database   = var.database_name

  schema     = each.value.schema
  name       = each.value.view.view_name
  is_secure  = true

  statement = file(each.value.view.view_sql)
}

resource "snowflake_execute" "forecast" {
  for_each = var.forecasts

  execute = file(each.value.fcast_sql)

  revert = <<SQL
    DROP FORECAST IF EXISTS ${var.database_name}.${each.value.schema}.${each.key};
  SQL

  query = <<SQL
    SHOW FORECASTS LIKE '${each.key}' IN SCHEMA ${var.database_name}.${each.value.schema};
  SQL

  depends_on = [ snowflake_view.this ]
}


# Task to run cron job automatically
resource "snowflake_task" "copy_task" {
  for_each = var.forecasts

  name      = "TASK_${upper(each.key)}_${var.environment}"
  database  = var.database_name
  schema    = each.value.schema

  warehouse = each.value.warehouse
  
  schedule {
    using_cron = each.value.cron_schedule
  }

  sql_statement = format(
      "INSERT INTO %s.%s.%s SELECT * FROM TABLE(SNOWFLAKE.ML.FORECAST!PREDICT( FORECAST_NAME => '%s.%s.%s', HORIZON => %s));",
    var.database_name,
    each.value.schema,
    each.value.forecast_results_table,

    var.database_name,
    each.value.schema,  
    each.key,
    each.value.horizon

  )

  started = true
  
  depends_on = [ snowflake_execute.forecast ]
}