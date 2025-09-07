locals {
  env        = upper(var.environment)
  suffix     = upper(local.env)
  db_name    = var.database_name
  allowed_locations = [
    for p in var.pipelines :
    "s3://${p.source_bucket}/${p.source_prefix}"
  ]
  stg_schema = { for k,v in var.pipelines : k => coalesce(v.staging_schema, v.schema_name) }
  proc_is_sql = { for k,v in var.pipelines : k => (upper(v.procedure_lang) == "SQL") }
  warehouse   = var.warehouse
}

# ---------- AWS role trusted by Snowflake for S3 read ----------
data "aws_iam_policy_document" "assume_by_snowflake" {
  statement {
    sid     = "TrustSnowflake"
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.snowflake_aws_principal_arn]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.snowflake_external_id]
    }
  }
}

resource "aws_iam_role" "snowflake_s3_access" {
  name                 = "snowflake-s3-batch-${lower(local.env)}"
  assume_role_policy   = data.aws_iam_policy_document.assume_by_snowflake.json
  description          = "Snowflake read-only S3 access (${lower(local.env)})"
  max_session_duration = 3600
}

# Aggregate S3 permissions for all pipeline prefixes
data "aws_iam_policy_document" "s3_read" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = flatten([
      for p in var.pipelines : [
        "arn:aws:s3:::${p.source_bucket}",
        "arn:aws:s3:::${p.source_bucket}/*"
      ]
    ])
  }
}

resource "aws_iam_policy" "s3_read" {
  name   = "snowflake-s3-batch-read-${lower(local.env)}"
  policy = data.aws_iam_policy_document.s3_read.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.snowflake_s3_access.name
  policy_arn = aws_iam_policy.s3_read.arn
}

# ---------- Snowflake storage integration shared for all pipelines ----------
resource "snowflake_storage_integration" "s3" {
  name                 = "S3_INT_${upper(local.env)}"
  type                 = "EXTERNAL_STAGE"
  storage_provider     = "S3"
  storage_aws_role_arn = aws_iam_role.snowflake_s3_access.arn

  storage_allowed_locations = local.allowed_locations
  enabled                   = true
  comment                   = "Batch COPY integration limited to Dev prefixes"
}

# CSV File format - use the same schema
resource "snowflake_file_format" "csv" {
  for_each  = var.pipelines
  name      = "FF_${upper(each.key)}_${upper(local.env)}"
  database  = local.db_name
  schema    = each.value.schema_name
  format_type                  = "CSV"
  field_delimiter              = coalesce(each.value.file_format.delimiter, ",")
  field_optionally_enclosed_by = coalesce(each.value.file_format.field_optionally_enclosed_by, "'")
  trim_space                   = coalesce(each.value.file_format.trim_space, true)
  empty_field_as_null          = true
  null_if                      = ["", "NULL", "null"]
  parse_header                 = true

  depends_on = [ snowflake_storage_integration.s3 ]
}

resource "snowflake_stage" "s3" {
  for_each = var.pipelines

  name                = "STG_${upper(each.key)}_${local.env}"
  database            = local.db_name
  schema              = each.value.schema_name
  url                 = "s3://${each.value.source_bucket}/${each.value.source_prefix}"
  storage_integration = snowflake_storage_integration.s3.name

  depends_on = [ snowflake_file_format.csv ]
}

# SQL-language procedures
resource "snowflake_procedure_sql" "proc_sql" {
  for_each = { for k, v in var.pipelines : k => v if true } # all pipelines use SQL procs

  database   = local.db_name
  schema     = each.value.schema_name
  name       = each.value.procedure_name

  arguments {
    arg_name      = "PATTERN"
    arg_data_type = "STRING"
  }

  arguments {
    arg_name      = "DB_NAME"
    arg_data_type = "STRING"
  }

  arguments {
    arg_name      = "SCHEMA_NAME"
    arg_data_type = "STRING"
  }

  arguments {
    arg_name      = "TARGET_TABLE"
    arg_data_type = "STRING"
  }

  arguments {
    arg_name      = "STAGE_NAME"
    arg_data_type = "STRING"
  }
  
  arguments {
    arg_name      = "FILE_FORMAT_NAME"
    arg_data_type = "STRING"
  }

  arguments {
    arg_name      = "SPROC_NAME"
    arg_data_type = "STRING"
  }

  return_type = "VARCHAR"
  execute_as  = "OWNER"

  # Reference the SQL script file per pipeline
  procedure_definition = file(each.value.procedure_file)

    depends_on = [
    snowflake_file_format.csv
  ]
}


# Task to run cron job automatically
resource "snowflake_task" "copy_task" {
  for_each = var.pipelines

  name      = "TASK_${upper(each.key)}_${local.env}"
  database  = local.db_name
  schema    = each.value.schema_name
  warehouse = var.warehouse
  
  schedule {
    using_cron = each.value.cron_schedule
  }

  sql_statement = format(
      "CALL %s.%s.%s('%s','%s','%s','%s','%s','%s','%s');",
    local.db_name,
    each.value.schema_name,
    each.value.procedure_name,

    ".*\\.csv",
    local.db_name,
    each.value.schema_name,
    each.value.target_table,
    snowflake_stage.s3[each.key].name,               
    snowflake_file_format.csv[each.key].name,
    each.value.procedure_name
  

  )

  started = true
  
  depends_on = [
    snowflake_procedure_sql.proc_sql, snowflake_stage.s3
  ]
}