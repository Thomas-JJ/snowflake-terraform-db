# Snowflake Terraform Data Pipelines

An intelligent, configurable Infrastructure-as-Code solution that automatically manages Snowflake databases, tables, stages, and data ingestion pipelines using Terraform. Routes files from AWS S3 to Snowflake tables with automated batch processing.

## Overview

This solution provides enterprise-grade data pipeline automation for Snowflake environments, automatically ingesting files from S3 landing zones to structured tables based on configurable pipeline definitions stored in Terraform configurations.

## Architecture

```
AWS S3 Buckets  →  External Stages  →  Snowflake Tables (STG_*, Base Tables)
     ↓                  ↓                       ↓
 Raw Data Files   Terraform-Managed        Structured Data
                  Pipeline Automation             ↓
                                                  ↓
                                            Snowflake Dynamic Tables
                                                    ↓
                                              Analytics / BI / Streamlit
```
🔎 Flow Explanation

AWS S3 Buckets
Source systems deliver raw data files (CSV, Parquet, etc.) into S3 buckets. These are the entry point into the data platform.

External Stages
Snowflake external stages are provisioned via Terraform, pointing to the correct S3 prefixes. They allow Snowflake to securely and directly access the raw files.

Snowflake Tables (STG + Base)

Staging Tables (STG_): Mirror the raw file structure, enriched with audit columns.

Base Tables: Merge, deduplicate, and enforce schema standards for long-term storage.
All of these are defined in Terraform modules for reproducibility.

Dynamic Tables
Dynamic tables act as automated materializations. They continuously maintain rollups, joins, and aggregates based on the underlying base tables.

Freshness is governed by TARGET_LAG (e.g., 5 minutes, 12 hours, or DOWNSTREAM).

Perfect for creating curated data marts without writing complex orchestration logic.

Analytics / BI / Streamlit
Downstream applications (Power BI, Tableau, Streamlit) connect to the dynamic tables.

These tables are optimized for consumption and always up to date within the defined lag.

Your Streamlit app, for example, can directly update or query dynamic tables for interactive analysis.

## Features

- **🎯 Intelligent Ingestion**: Route files based on S3 paths and patterns with automated COPY + MERGE operations
- **⚙️ Configuration-Driven**: Update pipeline rules through Terraform variables without code changes
- **🔒 Secure**: AWS IAM integration with Snowflake external stages using least-privilege access
- **📊 Observable**: Full task monitoring and warehouse credit management (Future Enhancement)
- **🚀 Scalable**: Multi-environment support with isolated configurations
- **🛡️ Reliable**: Built-in error handling with configurable failure behavior

## Quick Start

### Prerequisites

- Terraform >= 1.0
- AWS account with S3 buckets configured
- Snowflake account with admin access
- AWS Secrets Manager setup

### 1. Clone and Configure

```bash
git clone https://github.com/<your-org>/snowflake-terraform.git
cd snowflake-terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

### 2. Update Configuration

Edit `terraform.tfvars`:

```hcl
environment = "dev"
aws_region  = "us-east-2"

snowflake_secret_arn         = "arn:aws:secretsmanager:region:account:secret:snowflake-creds"
snowflake_external_id        = "your-external-id"
snowflake_aws_principal_arn  = "arn:aws:iam::account:role/snowflake-access-role"

db_base_name = "ANALYTICS"
alert_emails = ["alerts@email.com"]
```

### 3. Configure Pipeline Rules

Define your data pipelines in `terraform.tfvars`:

```hcl
pipelines = {
  sales_orders = {
    schema_name     = "SALES"
    staging_schema  = "SALES"
    source_bucket   = "your-data-bucket"
    source_prefix   = "orders/"
    target_table    = "ORDERS"
    staging_table   = "STG_ORDERS"
    merge_keys      = ["DATE", "STORE_ID"]
    cron_schedule   = "0 5 * * 1 UTC"
    pattern         = ".*orders_.*\\.csv"
    
    file_format = {
      type                         = "CSV"
      delimiter                    = ","
      skip_header                  = 1
      field_optionally_enclosed_by = "\""
      trim_space                   = true
    }
    
    procedure_name = "SP_COPY_MERGE_ORDERS"
    procedure_file = "../../modules/pipelines/procs/SP_COPY_MERGE_ORDERS.sql"
  }
}
```

### 4. Deploy

```bash
terraform init -reconfigure -upgrade
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Configuration

### Pipeline Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `schema_name` | ✅ | Target Snowflake schema name |
| `staging_schema` | ✅ | Staging schema for temporary tables |
| `source_bucket` | ✅ | AWS S3 bucket containing source files |
| `source_prefix` | ✅ | S3 prefix/folder path (e.g., "sales/") |
| `target_table` | ✅ | Final destination table name |
| `staging_table` | ✅ | Temporary staging table name (Not currently available) |
| `merge_keys` | ✅ | Columns used for MERGE operations (Not currently available) |
| `cron_schedule` | ✅ | Task execution schedule (cron format) |
| `pattern` | ✅ | Regex pattern for filename matching (Not currently available) |
| `file_format` | ✅ | Snowflake file format specification |
| `procedure_name` | ✅ | Stored procedure name for processing |
| `procedure_file` | ✅ | Path to SQL procedure file |
| `on_error` | ❌ | Error handling behavior (default: "ABORT_STATEMENT") |

### File Format Options

```hcl
file_format = {
  type                         = "CSV"           # CSV, JSON, PARQUET
  delimiter                    = ","             # Field delimiter
  skip_header                  = 1               # Number of header rows to skip
  field_optionally_enclosed_by = "\""            # Quote character
  trim_space                   = true            # Remove whitespace
  null_if                     = ["", "NULL"]     # Null value representations
  data_format                 = "MM-DD-YYYY"     # Specify format of date fields
}
```

### Schedule Configuration

Use standard cron expressions for task scheduling:

```hcl
cron_schedule = "0 5 * * 1 UTC"    # Weekly on Monday at 5 AM UTC
cron_schedule = "0 2 * * * UTC"    # Daily at 2 AM UTC
cron_schedule = "0 */4 * * * UTC"  # Every 4 hours
```

## Pipeline Components

Each data pipeline consists of four main components:

### 1. External Stage
- **Purpose**: Secure connection to AWS S3 bucket using IAM integration
- **Configuration**: Points to specific S3 bucket and prefix
- **Security**: Uses AWS IAM roles for cross-service authentication

### 2. File Format
- **Purpose**: Defines parsing rules for incoming files
- **Supported Types**: CSV, JSON, Parquet, and other Snowflake-supported formats
- **Customizable**: Delimiter, headers, encoding, date format, and null handling options

### 3. Stored Procedure
- **Purpose**: Implements COPY INTO and MERGE logic for data processing
- **Language**: SQL-based procedures with full Snowflake SQL support
- **Functionality**: Handles data transformation, validation, and upsert operations

### 4. Scheduled Task
- **Purpose**: Automates pipeline execution on configurable schedules
- **Schedule**: Flexible cron expressions for any timing requirements
- **Error Handling**: Configurable behavior for processing failures

## File Processing Logic

1. **Scheduled Execution**: Task runs based on cron schedule
2. **Stage Scanning**: External stage scans S3 prefix for matching files
3. **Pattern Matching**: Files filtered by regex pattern (Not currently available)
4. **Data Loading**: COPY INTO staging table with format specifications
5. **Data Merging**: MERGE from staging to target table using specified keys
6. **Cleanup**: Optional staging table truncation

### Processing Flow

```
File: "orders/orders_20250126.csv"
│
├─ Task executes on Mondays at 5am UTC (0 5 * * 1 UTC) Customizable using CRON Expression
├─ COPY INTO STG_ORDERS from @external_stage
├─ MERGE STG_ORDERS → ORDERS on [DATE, STORE_ID]
└─ Log results to task history ✅
```

## Security

### Credential Management
- **No Hardcoded Secrets**: All Snowflake credentials stored in AWS Secrets Manager
- **Dynamic Retrieval**: Terraform fetches credentials at runtime using data sources
- **Encrypted Storage**: All sensitive information encrypted at rest

### Access Control
- **IAM Integration**: AWS IAM roles provide secure cross-service authentication
- **External ID**: Additional security layer for role assumption
- **Principle of Least Privilege**: Service accounts with minimal required permissions
- **Network Security**: VPC endpoints and private networking support

### Secrets Manager Format

```json
{
  "account": "your-account-identifier",
  "organization": "your-organization-name", 
  "username": "terraform-service-user",
  "password": "your-secure-password",
  "role": "ACCOUNTADMIN",
  "warehouse": "COMPUTE_WH"
}
```

## Monitoring

### Current Features
- **Resource Monitors**: Warehouse credit quota management and alerts
- **Task History**: Built-in Snowflake task execution monitoring
- **Procedure Logging**: Detailed execution logs for each stored procedure

### Planned Enhancements
- CloudWatch integration for cross-platform monitoring
- Automated alerting for pipeline failures
- Cost monitoring and optimization recommendations
- Data quality metrics and validation alerts

### Key Metrics

Monitor these Snowflake metrics:
- Task execution success/failure rates
- Data processing volumes
- Warehouse credit consumption
- Pipeline execution duration

## Multi-Environment Deployment

This project supports isolated deployment environments with separate configurations:

### Development Environment
```bash
cd environments/dev
terraform init
terraform apply -var-file="terraform.tfvars"
```

### Staging Environment
```bash
cd environments/staging
terraform init
terraform apply -var-file="terraform.tfvars"
```

### Production Environment
```bash
cd environments/prod
terraform init
terraform apply -var-file="terraform.tfvars"
```

Each environment maintains separate:
- Snowflake databases and schemas
- AWS S3 bucket configurations
- Pipeline schedules and parameters
- Monitoring and alerting settings

## Troubleshooting

### Common Issues

**Terraform initialization fails**
- Ensure AWS credentials are properly configured
- Trust policy may need to be updated with the integration values
- Verify Snowflake provider version compatibility
- Check AWS Secrets Manager permissions

**Snowflake connection errors**
- Validate credentials in AWS Secrets Manager
- Confirm Snowflake account identifier format
- Verify network connectivity and IP whitelisting

**Pipeline execution failures**
- Review Snowflake task history: `SHOW TASKS LIKE '%TASK_NAME%'`
- Check stored procedure logs: `CALL SYSTEM$TASK_DEPENDENTS_ENABLE('task_name')`
- Validate S3 stage permissions and file availability
- Verify file format specifications match actual file structure

**Performance issues**
- Monitor warehouse size and auto-suspend settings
- Review query execution plans in Query History
- Check for optimal clustering and indexing strategies

### Debug Commands

```sql
-- Check task status
SHOW TASKS LIKE '%SALES%';

-- View task execution history
SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY()) 
WHERE NAME LIKE '%SALES%' 
ORDER BY SCHEDULED_TIME DESC;

-- Test stored procedure manually
CALL SP_COPY_MERGE_ORDERS();

-- Check stage file listing
LIST @external_stage_name;
```

## Cost Optimization

- **Warehouse Auto-Suspend**: Automatic shutdown when idle
- **Right-Sized Compute**: Warehouse scaling based on workload requirements
- **Efficient Scheduling**: Optimal task timing to minimize compute waste
- **Resource Monitoring**: Credit usage alerts and budget controls

## Terraform Resources

This project creates:
- Snowflake database and schemas
- External stages with AWS IAM integration
- Stored procedures for data processing
- Scheduled tasks for automation
- Resource monitors for cost control
- File formats for various data types

## Project Structure

```
.
├── environments/
│   ├── dev/                   # Development environment
│   ├── staging/               # Staging environment  
│   └── prod/                  # Production environment
└── modules/
    ├── infrastructure/        # Core Snowflake resources
    ├── tables/               # Table and schema definitions
    │   └── sales/            # Sales-specific schemas
    ├── pipelines/            # Pipeline automation
    ├── monitoring/           # Resource monitoring (future)
    └── security/             # Access control (future)
```

## Contributing

We welcome contributions to improve this project. Please follow these guidelines:

1. **Fork the repository** and create a feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following existing conventions and best practices

3. **Test your changes** in a development environment first

4. **Commit and push** your changes
   ```bash
   git commit -m "Add: Brief description of your changes"
   git push origin feature/your-feature-name
   ```

5. **Open a Pull Request** with detailed description of changes and testing performed

### Code Standards
- Follow Terraform best practices and naming conventions
- Include comprehensive documentation for new features
- Test all changes in development environment
- Use descriptive variable names and inline comments

## Support

For issues or questions:
1. Check Snowflake task history for execution details
2. Review CloudWatch logs for Terraform deployment issues  
3. Verify AWS Secrets Manager credential format
4. Test pipeline components individually using Snowflake SQL
5. Open GitHub issue with detailed error information

## License

This project is licensed under the MIT License - see the LICENSE file for details.