variable "database_name" {
  description = "Target database name ( Provided from Infrastrcuture)"
  type        = string
}

variable "dynamic_tables" {
  type = map(object({
    table_name        = string
    schema_name       = string
    target_lag        = string
    warehouse         = string

    query             = string

    initialize        = optional(string)
    comment           = optional(string)       
  }))
}
