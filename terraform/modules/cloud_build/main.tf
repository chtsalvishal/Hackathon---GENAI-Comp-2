# ---------------------------------------------------------------------------
# Cloud Build — GitHub-connected CI/CD triggers.
#
#   validate-trigger  — fires on every pull request; runs terraform fmt check,
#                       terraform validate, and Dataform compilation dry-run.
#   deploy-trigger    — fires on push to main branch; runs terraform apply
#                       and triggers a Dataform full-refresh workflow invocation.
#
# The GitHub connection must be authorised manually in the Cloud Console after
# first deploy (Cloud Build → Repositories → Connect repository).
# ---------------------------------------------------------------------------

resource "google_cloudbuildv2_connection" "github" {
  project  = var.project_id
  location = var.region
  name     = "github-connection"

  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = "projects/${var.project_id}/secrets/github-token/versions/latest"
    }
  }
}

resource "google_cloudbuildv2_repository" "intelia_warehouse" {
  project           = var.project_id
  location          = var.region
  name              = "intelia-warehouse"
  parent_connection = google_cloudbuildv2_connection.github.name
  remote_uri        = "https://github.com/${var.github_repo}.git"
}

# ---------------------------------------------------------------------------
# PR Validation Trigger
# ---------------------------------------------------------------------------

resource "google_cloudbuild_trigger" "validate" {
  project         = var.project_id
  location        = var.region
  name            = "validate-pr"
  description     = "Validates Terraform and Dataform on every pull request."
  service_account = "projects/${var.project_id}/serviceAccounts/${var.cloudbuild_sa_email}"

  repository_event_config {
    repository = google_cloudbuildv2_repository.intelia_warehouse.id
    pull_request {
      branch          = ".*"
      comment_control = "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
    }
  }

  filename = "cloudbuild-validate.yaml"
}

# ---------------------------------------------------------------------------
# Deploy Trigger (push to main)
# ---------------------------------------------------------------------------

resource "google_cloudbuild_trigger" "deploy" {
  project         = var.project_id
  location        = var.region
  name            = "deploy-main"
  description     = "Deploys Terraform changes and triggers Dataform full-refresh on push to main."
  service_account = "projects/${var.project_id}/serviceAccounts/${var.cloudbuild_sa_email}"

  repository_event_config {
    repository = google_cloudbuildv2_repository.intelia_warehouse.id
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild-deploy.yaml"
}
