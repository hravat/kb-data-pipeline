-- Snowflake setup for the TEST environment. Run in a Snowflake worksheet as ACCOUNTADMIN.
-- Data: transactions_YYYYMMDD.csv  (transaction_id,account_id,transaction_timestamp,amount,currency,status)
--
-- Object names match setup.sql (file format, stage, table, pipe). What differs for test:
--   database     TEST_KB_DATA_PIPELINE        (created by Terraform, with the RAW schema)
--   bucket       kb-data-pipeline-landing-hravat-test
--   AWS role     kb-pipeline-snowflake-access-test
--   integration  S3_LANDING_INT_TEST          (integrations are account-level, so the name must differ
--                                             from the dev and unsuffixed ones)
--
-- Order:
--   PART 1  creates the integration. Copy its two output values.
--   PART 2  file format, stage, table, pipe. Copy the queue ARN from SHOW PIPES.
--   Then add the three values as GitHub variables on the test environment and run the deploy-test workflow again (open a new pull request or push to the PR).

-- =====================================================================================
-- PART 1: storage integration (lets Snowflake read the test bucket through the test IAM role)
-- The role must already exist in AWS (created by the deploy-test workflow).
-- =====================================================================================
USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION IF NOT EXISTS s3_landing_int_test
  TYPE                      = EXTERNAL_STAGE
  STORAGE_PROVIDER          = 'S3'
  ENABLED                   = TRUE
  STORAGE_AWS_ROLE_ARN      = 'arn:aws:iam::379937168897:role/kb-pipeline-snowflake-access-test'
  STORAGE_ALLOWED_LOCATIONS = ('s3://kb-data-pipeline-landing-hravat-test/transactions/');

-- Copy these two rows into the GitHub test variables:
--   STORAGE_AWS_IAM_USER_ARN    -> SNOWFLAKE_IAM_USER_ARN
--   STORAGE_AWS_EXTERNAL_ID     -> SNOWFLAKE_EXTERNAL_ID
DESC INTEGRATION s3_landing_int_test;

-- =====================================================================================
-- PART 2: file format, stage, table, pipe
-- =====================================================================================
USE ROLE ACCOUNTADMIN;
USE DATABASE TEST_KB_DATA_PIPELINE;
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
  URL                 = 's3://kb-data-pipeline-landing-hravat-test/transactions/'
  STORAGE_INTEGRATION = s3_landing_int_test
  FILE_FORMAT         = (FORMAT_NAME = 'transactions_csv');

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

-- Copy notification_channel (the SQS queue ARN) into the GitHub test variable SNOWPIPE_QUEUE_ARN.
SHOW PIPES LIKE 'transactions_pipe';

-- =====================================================================================
-- AFTER the GitHub variables are set and the deploy-test workflow has run again:
-- =====================================================================================
-- LIST @landing_stage;     -- works only once the AWS role trusts Snowflake (after that workflow run)
--
-- Upload a CSV to s3://kb-data-pipeline-landing-hravat-test/transactions/, wait about a minute, then:
-- SELECT SYSTEM$PIPE_STATUS('TEST_KB_DATA_PIPELINE.RAW.TRANSACTIONS_PIPE');
--
-- SELECT file_name, status, row_count, first_error_message, last_load_time
-- FROM TABLE(TEST_KB_DATA_PIPELINE.INFORMATION_SCHEMA.COPY_HISTORY(
--   TABLE_NAME => 'RAW_TRANSACTIONS', START_TIME => DATEADD('day', -1, CURRENT_TIMESTAMP())))
-- ORDER BY last_load_time DESC;
--
-- SELECT * FROM TEST_KB_DATA_PIPELINE.RAW.RAW_TRANSACTIONS ORDER BY _loaded_at DESC LIMIT 20;
--
-- Files already in the bucket before the notification existed are not loaded automatically:
-- ALTER PIPE TEST_KB_DATA_PIPELINE.RAW.TRANSACTIONS_PIPE REFRESH;
