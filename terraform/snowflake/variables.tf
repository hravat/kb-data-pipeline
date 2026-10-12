variable "database_name" {
  description = "Snowflake database to create"
  type        = string
  default     = "KB_DATA_PIPELINE"
}

variable "schema_name" {
  description = "Schema inside the database for the raw loaded data"
  type        = string
  default     = "RAW"
}
