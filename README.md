# kb-data-pipeline

Take-home exercise: a reusable capability to move transaction CSV files into a cloud data platform.

```
Local files  ->  S3 landing bucket  ->  SQS event  ->  Snowpipe  ->  Snowflake RAW_TRANSACTIONS
                                                          ^
                              Airflow orchestrates and monitors (DAG)
```

Input files look like `data/transactions_20260901.csv` and land in S3 as
`s3://data-platform-landing/transactions/2026/09/01/transactions_20260901.csv`.

## Status

| Part | State |
|---|---|
| Upload script + unit tests | Written (copy in from `Interview Prep/exercise`) |
| Local AWS emulator (`docker-compose.yml`) | In repo |
| S3 bucket + event notification (Terraform) | Planned |
| Snowflake objects + Snowpipe (SQL) | Planned |
| GitHub Actions CI/CD with environments | Planned |
| Airflow DAG | Planned |

## Approach

### 1. Upload (Python CLI)
`python upload_to_s3.py data/ --bucket data-platform-landing [--dry-run]`

- The date in the file name decides the S3 key (`<dataset>/YYYY/MM/DD/<file>`). Files with other names are rejected and reported.
- A SHA256 checksum is stored as object metadata. Re-running skips unchanged files. A key that exists with different content fails instead of overwriting landed data.
- Returns a summary (uploaded / skipped / failed) and a non-zero exit code on failure, so Airflow or CI can act on it.
- Tests mock the S3 client, so no AWS account is needed.

### 2. S3 and event notification
- Landing bucket: public access blocked, versioning on, encryption at rest, TLS-only policy.
- `ObjectCreated` events on the `transactions/` prefix go to the SQS queue that Snowpipe provides.
- Airflow needs its own copy of the event. S3 cannot send the same event on the same prefix to two separate notification configurations, so fan out with SNS (or EventBridge) to the Snowpipe queue and an Airflow queue.
- Locally, `docker-compose.yml` runs an AWS emulator on port 4566 so the bucket and queue can be exercised without a real account.

### 3. Snowpipe
- How Snowflake reaches S3: a **storage integration** backed by an IAM role (read-only on the bucket/prefix, trust policy with Snowflake's IAM user and external ID). No access keys.
- Objects: file format (CSV, skip header, null handling), external stage on the landing prefix, `RAW_TRANSACTIONS` table (6 source columns plus source file and load time), and a pipe with `AUTO_INGEST = TRUE`.
- How the right files are selected: the stage points at the `transactions/` prefix and the pipe loads new objects as events arrive.
- If the same file is processed again: Snowpipe keeps load history per file, so a file it has already loaded is not loaded twice. The upload script also avoids re-uploading unchanged files. A same-name file with changed content is rejected at upload.
- Snowflake cannot be emulated locally, so the SQL is kept as files and tested by checking the statements, not by running them.

### 4. CI/CD (GitHub Actions)
- **On pull request:** lint and unit tests.
- **On merge to `main`:** build one versioned artifact (git tag plus commit SHA) and deploy to `dev`. The same artifact is promoted to `test` and then `prod` unchanged.
- **Environments:** `dev`, `test`, `prod`. Each holds its own variables (bucket, Snowflake database and role), so the code is the same and only config differs.
- **Approval gate:** `prod` requires reviewers and deploys from `main` only. `main` is branch-protected (PR, review, required checks).
- Deploy jobs are stubs, as the brief does not require a real deployment.

### 5. Airflow
- Runs on managed Airflow (for example MWAA) or Kubernetes, one per environment. The pipeline copies versioned DAGs to it. Credentials come from Airflow Connections backed by a secrets manager.
- Two DAGs: one runs the upload; one is triggered by the S3 event (SQS sensor) and checks that Snowpipe loaded the file, then can trigger downstream work such as dbt.
- Snowpipe is already event-driven, so Airflow is not needed for the load itself. It adds scheduling of the source pull, retries, alerting, backfills by run date and downstream dependencies.

## Trade-offs
- **Snowpipe vs `COPY INTO` from Airflow:** Snowpipe needs less orchestration and loads within about a minute of the file landing. `COPY INTO` gives explicit run-level control and is simpler to test. Snowpipe was chosen; the choice is easy to revisit.
- **Checksum in object metadata:** simple and works without extra infrastructure. A separate audit table would be the next step if load history is needed beyond Snowpipe's own.

## Not done / next steps
- Schema drift handling and a rejects table for bad rows.
- Monitoring on the dead-letter queue and on Snowpipe lag.
- Real deployment steps in the CI/CD pipeline.
