# ---------------------------------------------------------------------------
# Secret Manager — creates secret resources with empty initial versions.
# Actual secret values are populated manually or via bootstrap.sh post-deploy.
# ---------------------------------------------------------------------------

resource "google_secret_manager_secret" "github_token" {
  project   = var.project_id
  secret_id = "github-token"

  replication {
    auto {}
  }

  labels = {
    purpose = "dataform-git-auth"
  }
}

resource "google_secret_manager_secret" "looker_api_key" {
  project   = var.project_id
  secret_id = "looker-api-key"

  replication {
    auto {}
  }

  labels = {
    purpose = "looker-api-connection"
  }
}

resource "google_secret_manager_secret" "gemini_api_key" {
  project   = var.project_id
  secret_id = "gemini-api-key"

  replication {
    auto {}
  }

  labels = {
    purpose = "gemini-api-reserved"
  }
}

# ---------------------------------------------------------------------------
# Placeholder initial versions (empty data; real values filled post-deploy).
# Using a single space as the payload satisfies the API requirement for a
# non-null secret payload while making it obvious the value is not yet set.
# Bootstrap scripts or manual entry must overwrite these before use.
# ---------------------------------------------------------------------------

resource "google_secret_manager_secret_version" "github_token_placeholder" {
  secret      = google_secret_manager_secret.github_token.id
  secret_data = "REPLACE_WITH_GITHUB_PAT"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret_version" "looker_api_key_placeholder" {
  secret      = google_secret_manager_secret.looker_api_key.id
  secret_data = "REPLACE_WITH_LOOKER_API_KEY"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret_version" "gemini_api_key_placeholder" {
  secret      = google_secret_manager_secret.gemini_api_key.id
  secret_data = "REPLACE_WITH_GEMINI_API_KEY"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# ---------------------------------------------------------------------------
# IAM — Dataform SA can access github-token
# ---------------------------------------------------------------------------

resource "google_secret_manager_secret_iam_member" "dataform_github_token" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.github_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.dataform_sa_email}"
}

# ---------------------------------------------------------------------------
# IAM — Cloud Build SA can access github-token for CI/CD pipeline
# ---------------------------------------------------------------------------

resource "google_secret_manager_secret_iam_member" "cloudbuild_sa_github_token" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.github_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.cloudbuild_sa_email}"
}

# ---------------------------------------------------------------------------
# IAM — Cloud Build service agent (GCP-managed) needs access to github-token
# to authenticate the GitHub App connection. The service agent email follows
# the pattern service-{project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com
# ---------------------------------------------------------------------------

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_secret_manager_secret_iam_member" "cloudbuild_agent_github_token" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.github_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}
