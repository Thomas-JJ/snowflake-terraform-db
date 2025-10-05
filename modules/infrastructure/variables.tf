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
    max_cluster_count                 = number
    min_cluster_count                 = number
    scaling_policy                    = string
    comment                           = string
    enable_query_acceleration         = bool
    query_acceleration_max_scale_factor = number

    credit_limit = object({
      credit_quota  = number
      frequency     = string
    })

  }))
}
