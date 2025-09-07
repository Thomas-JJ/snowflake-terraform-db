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
    account_name       = var.snowflake_account_name     # e.g. "xy12345" or "xy12345.us-east-1.aws"
    organization_name =  var.snowflake_organization_name

    user          = var.snowflake_user
    role          = var.snowflake_role

    warehouse   = var.snowflake_warehouse

    authenticator = "SNOWFLAKE_JWT"           # <- required for key-pair auth
}
