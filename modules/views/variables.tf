variable "database_name" {
  description = "Target database name ( Provided from Infrastrcuture)"
  type        = string
}


variable "views" {
  type = map(object({
    schema     = string
    name       = string
    is_secure  = optional(bool, true)
    query      = string

  }))
}
