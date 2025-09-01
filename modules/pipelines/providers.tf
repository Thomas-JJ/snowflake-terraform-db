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
