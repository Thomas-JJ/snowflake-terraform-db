variable "environment" {
  type        = string
}

variable "database_name" {
  description = "Target database name ( Provided from Infrastrcuture)"
  type        = string
}



variable "role_access" {
  description = "Map of roles with warehouse and schema-level access"
  type = map(object({
    warehouses = string
    schemas    = map(list(string)) # schema_name => [privileges]
    views_only  = optional(bool, true)
  }))
}