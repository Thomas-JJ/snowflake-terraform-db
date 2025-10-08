variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "db_base_name" {
  description = "Base Name of the database"
  type        = string
}

variable "schemas" {
  description = "list of schema names to be created"
  type = list(string)
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
