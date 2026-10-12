-- Snowflake setup for the transactions pipeline. Run in a Snowflake worksheet as ACCOUNTADMIN.
-- Data: transactions_YYYYMMDD.csv  (transaction_id,account_id,transaction_timestamp,amount,currency,status)
--
-- Run it in three passes:
--   PART 1  first, so Terraform can log in with the key.
--   (then run `terraform apply` in terraform/, which creates database KB_DATA_PIPELINE and schema RAW)
--   PART 2  creates the integration. Copy its two output values into the AWS role's trust policy.
--   PART 3  once the AWS role trusts Snowflake: format, stage, table, pipe.

-- =====================================================================================
-- PART 1: register the public key for key-pair login (public key only, safe to keep here)
-- =====================================================================================
USE ROLE ACCOUNTADMIN;

ALTER USER "HUSSAIN.RAVAT.NZ@GMAIL.COM" SET RSA_PUBLIC_KEY='MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyj3TZqOAdZPSgMmFty2pqSQOtPVy8vDjk3FAFDxhwAYOQGibNH7d85MxYwK9nhoJLlivASFrLcV/p5JKdIpy8lVu+QwuzLrhhw3Id6bnwk01R2jdtMuwd0tpotW++yMFrwgh9Nn7NvLU9sDMgcvhYBMpvTgKySHzluPXHU3jkGgyzDSEikxM1Q9089XWne1W0QiNlQUgo1J+SuLqM9ey3JgUYiPzm2Qvvrgs+SqUAIlo+OkjPDtAW0/dbVI7KpLHsGM6+nhk6xRPqjtkVZB5KS2yugy7Zj4JTRZhtmA5sQxjvr+hhbly3Ajbf9dFs/Fs70W2QduiwfI5L6l2FpGwoQIDAQAB';

-- Check: RSA_PUBLIC_KEY_FP should show a SHA256:... value
DESC USER "HUSSAIN.RAVAT.NZ@GMAIL.COM";

-- =====================================================================================
-- PART 2: storage integration (lets Snowflake read the bucket through an AWS IAM role)
-- The role must exist in AWS. See the notes at the bottom.
-- =====================================================================================
USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION IF NOT EXISTS s3_landing_int
  TYPE                      = EXTERNAL_STAGE
  STORAGE_PROVIDER          = 'S3'
  ENABLED                   = TRUE
  STORAGE_AWS_ROLE_ARN      = 'arn:aws:iam::379937168897:role/kb-pipeline-snowflake-access'
  STORAGE_ALLOWED_LOCATIONS = ('s3://kb-data-pipeline-landing-hravat/transactions/');

-- Copy STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID into the AWS role's trust policy.
DESC INTEGRATION s3_landing_int;

-- =====================================================================================
-- PART 3: file format, stage, table, pipe
-- =====================================================================================
USE ROLE ACCOUNTADMIN;
USE DATABASE KB_DATA_PIPELINE;
USE SCHEMA RAW;

CREATE FILE FORMAT IF NOT EXISTS transactions_csv
  TYPE                           = CSV
  FIELD_DELIMITER                = ','
  SKIP_HEADER                    = 1
  FIELD_OPTIONALLY_ENCLOSED_BY   = '"'
  TRIM_SPACE                     = TRUE
  NULL_IF                        = ('', 'NULL')
  TIMESTAMP_FORMAT               = 'YYYY-MM-DD"T"HH24:MI:SS'
  ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE;

CREATE STAGE IF NOT EXISTS landing_stage
  URL                 = 's3://kb-data-pipeline-landing-hravat/transactions/'
  STORAGE_INTEGRATION = s3_landing_int
  FILE_FORMAT         = (FORMAT_NAME = 'transactions_csv');

-- Works only once the AWS role trusts Snowflake. Lists the files already in the bucket.
LIST @landing_stage;

CREATE TABLE IF NOT EXISTS RAW_TRANSACTIONS (
  transaction_id        VARCHAR,
  account_id            VARCHAR,
  transaction_timestamp TIMESTAMP_NTZ,
  amount                NUMBER(18, 2),
  currency              VARCHAR(3),
  status                VARCHAR,
  _source_file          VARCHAR,
  _file_row_number      NUMBER,
  _loaded_at            TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Snowpipe remembers files it has loaded, so the same file is not loaded twice.
CREATE PIPE IF NOT EXISTS transactions_pipe
  AUTO_INGEST = TRUE
AS
COPY INTO RAW_TRANSACTIONS
  (transaction_id, account_id, transaction_timestamp, amount, currency, status,
   _source_file, _file_row_number)
FROM (
  SELECT $1, $2, $3, $4, $5, $6,
         METADATA$FILENAME,
         METADATA$FILE_ROW_NUMBER
  FROM @landing_stage
)
FILE_FORMAT = (FORMAT_NAME = 'transactions_csv');

-- notification_channel is the SQS queue ARN. Set it as the target of the S3 bucket's event notification.
SHOW PIPES LIKE 'transactions_pipe';

-- =====================================================================================
-- CHECKS (after uploading a file to the bucket)
-- =====================================================================================
-- SELECT SYSTEM$PIPE_STATUS('transactions_pipe');
--
-- SELECT file_name, status, row_count, first_error_message, last_load_time
-- FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
--   TABLE_NAME => 'RAW_TRANSACTIONS', START_TIME => DATEADD('day', -1, CURRENT_TIMESTAMP())))
-- ORDER BY last_load_time DESC;
--
-- SELECT * FROM RAW_TRANSACTIONS ORDER BY _loaded_at DESC LIMIT 20;
--
-- Files already in the bucket before the pipe existed are not loaded automatically:
-- ALTER PIPE transactions_pipe REFRESH;

-- =====================================================================================
-- AWS ROLE NOTES (kb-pipeline-snowflake-access)
-- 1. Permissions: s3:GetObject and s3:ListBucket on kb-data-pipeline-landing-hravat/transactions/*
-- 2. Trust policy: principal = STORAGE_AWS_IAM_USER_ARN, condition sts:ExternalId = STORAGE_AWS_EXTERNAL_ID
--    (both values come from DESC INTEGRATION in PART 2)
-- =====================================================================================
