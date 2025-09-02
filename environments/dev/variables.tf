variable "environment"                { type = string }
variable "aws_region"                  { type = string }
variable "snowflake_secret_arn"        { type = string }

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
