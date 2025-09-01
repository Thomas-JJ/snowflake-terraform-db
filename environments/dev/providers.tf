terraform {
  required_providers {
    snowflake = {
      source  = "snowflake-labs/snowflake"
      version = "~> 0.95"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10"
    }
  }
}

provider "aws" {}

provider "snowflake" {
  account_name      = local.snow.account
  organization_name = local.snow.organization
  user              = local.snow.username
  password          = local.snow.password
  role              = local.snow.role
  warehouse         = local.snow.warehouse
}

