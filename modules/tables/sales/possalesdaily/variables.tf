variable "database_name" {
  description = "Target database name"
  type        = string
}

variable "schema_name" {
  description = "Target schema name"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
