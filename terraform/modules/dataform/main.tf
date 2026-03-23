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
