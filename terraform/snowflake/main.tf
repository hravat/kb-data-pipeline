# Database for the pipeline's objects
resource "snowflake_database" "this" {
  name = var.database_name
}

# Schema for the raw loaded data
resource "snowflake_schema" "raw" {
  database = snowflake_database.this.name
  name     = var.schema_name
}
