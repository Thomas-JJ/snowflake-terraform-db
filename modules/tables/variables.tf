variable "database_name" {
  description = "Target database name ( Provided from Infrastrcuture)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}
