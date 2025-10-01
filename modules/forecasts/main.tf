
resource "snowflake_view" "this" {
  for_each = var.forecasts

  database   = var.database_name

  schema     = each.value.schema
  name       = each.value.historical_view.view_name
  is_secure  = true

  statement = file(each.value.historical_view.view_sql)
}

resource "snowflake_view" "that" {
  for_each = var.forecasts

  database   = var.database_name

  schema     = each.value.schema
  name       = each.value.future_features_view.view_name
  is_secure  = true

  statement = file(each.value.future_features_view.view_sql)
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

resource "snowflake_table" "forecast_results" {
  for_each = var.forecasts
  
  database = var.database_name
  schema   = each.value.schema
  name     = each.value.forecast_results_table
  change_tracking = true

  column {
    name = "SERIES"
    type = "VARCHAR(255)"
    nullable = false
  }

  column {
    name = "TS"
    type = "TIMESTAMP_NTZ"
    nullable = false
  }

  column {
    name = "FORECAST"
    type = "FLOAT"
    nullable = false
  }

  column {
    name = "LOWER_BOUND"
    type = "FLOAT"
    nullable = false
  }

  column {
    name = "UPPER_BOUND"
    type = "FLOAT"
    nullable = false
  }

  column {
    name = "LOAD_ID"
    type = "VARCHAR(36)"
    nullable = false
  }

  column {
    name = "LOAD_DATE"
    type = "TIMESTAMP_NTZ"
    nullable = false
  }

  comment = "Forecast resutls for ${each.key}"

  depends_on = [ snowflake_execute.forecast ]
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
    "INSERT INTO %s.%s.%s (SERIES, TS, FORECAST, LOWER_BOUND, UPPER_BOUND, LOAD_ID, LOAD_DATE) WITH LOAD_ID_COL AS (SELECT UUID_STRING() AS LOAD_ID) SELECT f.SERIES, f.TS, f.FORECAST, f.LOWER_BOUND, f.UPPER_BOUND, l.LOAD_ID, CURRENT_TIMESTAMP() as LOAD_DATE FROM TABLE(%s.%s.%s!FORECAST(FORECASTING_PERIODS => %s)) f CROSS JOIN LOAD_ID_COL l",

    var.database_name,
    each.value.schema,
    each.value.forecast_results_table,

    var.database_name,
    each.value.schema,  
    each.key,
    each.value.forecasting_periods
  )

  started = true
  
  depends_on = [ snowflake_table.forecast_results ]
}

