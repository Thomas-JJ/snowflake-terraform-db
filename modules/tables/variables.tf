variable "database_name" {
  description = "Target database name ( Provided from Infrastrcuture)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}


variable "tables" {
  type = map(object({
    
    table_name = string
    schema_name = string
    
    fields = map(object({
      
      field_name = string
      data_type = string
      nullable = bool
      comment = optional(string)
      default_value = optional(string)
      primary_key = bool

    }))

  }))
}
