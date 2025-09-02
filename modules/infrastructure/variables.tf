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
