variable "environment" {
  type        = string
}

variable "database_name" {
  description = "Target database name ( Provided from Infrastrcuture)"
  type        = string
}


variable "forecasts" {
  type = map(object({
    schema     = string
    fcast_sql      = string
    view = object({
        view_name     = string
        view_sql      = string
    })
    warehouse     = string
    horizon       = number
    cron_schedule = string

    forecast_results_table = string

  }))
}