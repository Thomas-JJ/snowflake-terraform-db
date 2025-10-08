﻿variable "environment"                { type = string }
variable "aws_region"                  { type = string }

variable "snowflake_account_name" { type = string}
variable "snowflake_organization_name" { type = string}
variable "snowflake_role" { type = string}
variable "snowflake_user" { type = string}
variable "snowflake_warehouse" { type = string }

variable "snowflake_external_id"       { type = string }
variable "snowflake_aws_principal_arn" { type = string }

variable "alert_emails" {
  type    = list(string)
  default = []
}

variable "db_base_name" { type = string }

variable "schemas" {
  type = list(string)
}

variable "audit_columns"{ 
  type = list(object({
      
      field_name = string
      data_type = string
      nullable = bool
      comment = optional(string)
      default_value = optional(string)

    }))
}


variable "tables" {
  type = map(object({
    
    table_name = string
    schema_name = string
    add_audit_columns = bool
    add_stage_table = bool
    change_tracking = bool
    fields = map(object({
      
      field_name = string
      data_type = string
      nullable = bool
      comment = optional(string)
      default_value = optional(string)
      primary_key = bool

    }))

  }))

  # ensure each table has at least one field
  validation {
    condition     = alltrue([for t in var.tables : length(t.fields) > 0])
    error_message = "Each table must have at least one field."
  }

  # ensure each table has at least one key field
  validation {
    condition = alltrue([
      for t in var.tables :
      length([for f in t.fields : f if f.primary_key]) >= 1
    ])
    error_message = "Each table must define at least one key field."
  }
}

variable "pipelines" {
  type = map(object({
    schema_name    = string
    staging_schema = optional(string)
    source_bucket  = string
    source_prefix  = string
    file_format = object({
      type                         = string
      delimiter                    = optional(string)
      skip_header                  = optional(number)
      field_optionally_enclosed_by = optional(string)
      trim_space                   = optional(bool)
      date_format                  = optional(string)
    })
    target_table  = string
    staging_table = string
    merge_keys    = list(string)
    cron_schedule = string
    on_error      = optional(string)
    pattern       = optional(string)

    procedure_name  = string                 # e.g. "SP_COPY_MERGE_ITEMSALES"
    procedure_lang  = string                 # "SQL" is the only currently support language 
    procedure_file  = string                 # relative path to .sql (from this module)
  }))
}
variable "dynamic_tables" {
  type = map(object({
    table_name        = string
    schema_name       = string
    target_lag        = string
    warehouse         = string
    query             = string            # relative path to .sql (from this module)

    initialize        = optional(string)
    comment           = optional(string)       
  }))
}

variable "views" {
  type = map(object({
    schema     = string
    name       = string
    is_secure  = optional(bool, true)  # setting to false allows accounts it is shared with to see the sql behind the view
    query      = string               # relative path to .sql (from this module)

  }))
}
variable "shares" {
  type = map(object({
    schema           = string
    consumer_accounts = list(string)
  }))
}

variable "forecasts" {
  type = map(object({
    schema     = string
    
    fcast_sql      = string
    
    historical_view = object({
        view_name     = string
        view_sql      = string
    })
    
    future_features_view = object({
        view_name     = string
        view_sql      = string
    })
    
    warehouse                 = string
    forecasting_periods       = number
    cron_schedule             = string

    forecast_results_table = string
  
  }))
}


variable "warehouses" {
  type = map(object({
    size                              = string
    auto_suspend                      = number
    auto_resume                       = bool
    initially_suspended               = bool
    
    comment                           = string

    credit_limit = object({
      credit_quota  = number
      frequency     = string
    })

  }))
}
