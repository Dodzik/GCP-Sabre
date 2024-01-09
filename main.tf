provider "google" {
  project = "sabre-project-voting"
}

resource "google_cloud_run_service" "voting-backend-11" {
  name     = "voting-backend-11"
  location = "us-central1"

  template {
    spec {
      containers {
          image = "gcr.io/sabre-project-voting/voting-backend-11@sha256:c1499b4b3b86b5b3940ea141a96a728d37452753b3069ff80289ff17135a80bb"

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
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.voting-backend-11.location
  service  = google_cloud_run_service.voting-backend-11.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_sql_database_instance" "instance" {
  name             = "compose-postgres"
  region           = "us-central1"
  database_version = "POSTGRES_13"

  settings {
    tier = "db-f1-micro"
    availability_type = "ZONAL"
    ip_configuration {
      ipv4_enabled = true
    }
  }

}

resource "google_sql_database" "database" {
  name     = "compose-postgres"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  name     = "postgres"
  instance = google_sql_database_instance.instance.name
  password = "postgres"
}

resource "google_cloud_run_service" "voting-frontend" {
  name     = "voting-frontend"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/sabre-project-voting/voting-front@sha256:553a58133dbd77c6969b667e688932b5bdc76d59085a7aad04892b26a5164774"
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
  location = google_cloud_run_service.voting-frontend.location
  service  = google_cloud_run_service.voting-frontend.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_storage_bucket" "function_bucket" {
  name     = "function_reminder_bucket"
  location = "us-central1"

  versioning {
    enabled = true
  }
}


resource "google_cloudfunctions_function" "email_function" {
  name        = "email-function"
  runtime     = "python310"
  entry_point = "check_and_send_email"
  trigger_http = true

  source_archive_bucket = "function_reminder_bucket"
  source_archive_object = "email_reminder.zip"

  environment_variables = {
    DB_USER     = "postgres",
    DB_PASSWORD = "postgres",
    DB_NAME     = "compose-postgres",
    DB_HOST     = "34.27.44.197",
    DB_CONNECTION_NAME = google_sql_database_instance.instance.connection_name
  }
  region = "us-central1"
}

resource "google_cloud_scheduler_job" "email_function_scheduler" {
  name     = "email-function-scheduler"
  region = "us-central1"

  schedule = "0 6 * * *"
  time_zone = "UTC"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.email_function.https_trigger_url
  }
}

