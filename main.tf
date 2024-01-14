provider "google" {
  project = var.project_id
}

resource "google_cloud_run_service" "voting-backend-11" {
  name     = "voting-backend-11"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/voting-backend-11@sha256:ae5c81abad5280e59bfc5125a485ecc378363b412a70dc8ead8fbf6aae4509e0"

        env {
          name  = "DB_URL"
          value = "postgresql://postgres:postgres@/compose-postgres?host=/cloudsql/${google_sql_database_instance.instance.connection_name}"
        }
      }
    }
    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.voting-backend-11.location
  service     = google_cloud_run_service.voting-backend-11.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_sql_database_instance" "instance" {
  name             = var.db_instance_name
  region           = var.region
  database_version = var.db_version

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled = true
    }
  }
}

resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.instance.name
  password = var.db_password
}

resource "google_cloud_run_service" "voting-frontend" {
  name     = "voting-frontend"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/voting-front@sha256:553a58133dbd77c6969b667e688932b5bdc76d59085a7aad04892b26a5164774"
        ports {
          container_port = 80
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_policy" "noauth-frontend" {
  location    = google_cloud_run_service.voting-frontend.location
  service     = google_cloud_run_service.voting-frontend.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_storage_bucket" "function_bucket" {
  name     = "function_reminder_bucket"
  location = var.region

  versioning {
    enabled = true
  }
}

resource "google_cloudfunctions_function" "email_function" {
  name                 = "email-function"
  runtime              = "python310"
  entry_point          = "check_and_send_email"
  trigger_http         = true
  source_archive_bucket = "function_reminder_bucket"
  source_archive_object = "email_reminder.zip"

  environment_variables = {
    DB_USER             = var.db_user
    DB_PASSWORD         = var.db_password
    DB_NAME             = var.db_name
    DB_HOST             = var.db_host
    DB_CONNECTION_NAME  = google_sql_database_instance.instance.connection_name
  }

  region = var.region
}

resource "google_cloud_scheduler_job" "email_function_scheduler" {
  name      = "email-function-scheduler"
  region    = var.region
  schedule  = "0 6 * * *"
  time_zone = "UTC"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.email_function.https_trigger_url
  }
}
