variable "database_name" {
  description = "Target database name ( Provided from Infrastrcuture)"
  type        = string
}


variable "shares" {
  type = map(object({
    schema           = string
    consumer_accounts = list(string)
  }))
}