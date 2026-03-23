# ---------------------------------------------------------------------------
# Dataform Repository — wired to GitHub with Secret Manager auth token
# ---------------------------------------------------------------------------

resource "google_dataform_repository" "main" {
  provider = google-beta

  name    = "intelia-warehouse"
  region  = var.region
  project = var.project_id

  git_remote_settings {
    url                                 = "https://github.com/chtsalvishal/Hackathon---GENAI-Comp-2"
    default_branch                      = "main"
    authentication_token_secret_version = var.github_token_secret_name
  }

  workspace_compilation_overrides {
    default_database = var.project_id
    schema_suffix    = ""
  }
}

# ---------------------------------------------------------------------------
# Dataform Service Account IAM — managed in the IAM module; the SA email is
# passed into this module purely for any resource-level bindings needed here.
# The project-level bindings (bigquery.dataEditor, bigquery.jobUser) are
# already applied in modules/iam/main.tf.
# ---------------------------------------------------------------------------

# Grant the Dataform SA the ability to invoke the Dataform repository
# (dataform.repositories.get / dataform.workspaces.*)
resource "google_project_iam_member" "dataform_sa_dataform_editor" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${var.dataform_sa_email}"
}

# Grant the Dataform SA access to read the GitHub token secret
resource "google_secret_manager_secret_iam_member" "dataform_sa_github_token" {
  project   = var.project_id
  secret_id = var.github_token_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.dataform_sa_email}"
}

# ---------------------------------------------------------------------------
# Dataform Release Configuration — production release from main branch.
# This is the compilation target used by all workflow configurations.
# ---------------------------------------------------------------------------

resource "google_dataform_repository_release_config" "production" {
  provider   = google-beta
  project    = var.project_id
  region     = var.region
  repository = google_dataform_repository.main.name

  name            = "production"
  git_commitish   = "main"
  cron_schedule   = "0 12 * * *"  # compile at noon UTC daily (ahead of midnight refresh)
  time_zone       = "UTC"

  code_compilation_config {
    default_database = var.project_id
    default_schema   = "gold"
    default_location = var.region
    assertion_schema = "dataform_assertions"
  }
}

# ---------------------------------------------------------------------------
# Dataform Workflow Configuration — daily full refresh.
# Replaces the Python script that manually called the Dataform API.
# Runs all tables at 14:30 UTC (after midnight AEDT compilation at 12:00 UTC).
# ---------------------------------------------------------------------------

resource "google_dataform_repository_workflow_config" "daily_full_refresh" {
  provider   = google-beta
  project    = var.project_id
  region     = var.region
  repository = google_dataform_repository.main.name

  name           = "daily-full-refresh"
  release_config = google_dataform_repository_release_config.production.id
  cron_schedule  = "30 14 * * *"  # 14:30 UTC = 00:30 AEDT
  time_zone      = "UTC"

  invocation_config {
    fully_refresh_incremental_tables_enabled = true
    transitive_dependencies_included         = true
    transitive_dependents_included           = true
  }

  depends_on = [google_dataform_repository_release_config.production]
}
