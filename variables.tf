variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "sabre-project-voting"
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "us-central1"
}

variable "db_instance_name" {
  description = "Google Cloud SQL Database Instance Name"
  type        = string
  default     = "compose-postgres"
}

variable "db_version" {
  description = "Database version for Cloud SQL instance"
  type        = string
  default     = "POSTGRES_13"
}

variable "db_tier" {
  description = "Database tier for Cloud SQL instance"
  type        = string
  default     = "db-f1-micro"
}

variable "db_user" {
  description = "Database user for Cloud SQL instance"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database password for Cloud SQL instance"
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "Database name for Cloud SQL instance"
  type        = string
  default     = "compose-postgres"
}

variable "db_host" {
  description = "Database host for Cloud SQL instance"
  type        = string
  default     = "34.27.44.197"
}
