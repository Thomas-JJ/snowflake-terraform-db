variable "database_name" {
  description = "Target database name ( Provided from Infrastrcuture)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
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
