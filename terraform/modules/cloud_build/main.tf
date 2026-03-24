# ---------------------------------------------------------------------------
# Cloud Build — CI/CD triggers wired to GitHub.
#
# SETUP REQUIRED before applying this module:
#   1. Go to Cloud Console → Cloud Build → Repositories (2nd gen)
#   2. Click "Create host connection" → choose GitHub
#   3. Install the Cloud Build GitHub App on the repo
#   4. Note the installation ID from the URL
#   5. Set github_app_installation_id in terraform.tfvars
#   6. Re-run terraform apply
#
# Until github_app_installation_id is set (non-zero), this module creates
# nothing so the rest of the apply succeeds.
# ---------------------------------------------------------------------------

locals {
  github_connected = var.github_app_installation_id != 0
}

resource "google_cloudbuildv2_connection" "github" {
  count    = local.github_connected ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = "github-connection"

  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = "projects/${var.project_id}/secrets/github-token/versions/latest"
    }
  }

  # The OAuth token secret is managed by the Cloud Console GitHub App setup.
  # Prevent Terraform from overwriting the working credential on updates.
  lifecycle {
    ignore_changes = [github_config]
  }
}

resource "google_cloudbuildv2_repository" "intelia_warehouse" {
  count             = local.github_connected ? 1 : 0
  project           = var.project_id
  location          = var.region
  name              = "intelia-warehouse"
  parent_connection = google_cloudbuildv2_connection.github[0].name
  remote_uri        = "https://github.com/${var.github_repo}.git"
}

resource "google_cloudbuild_trigger" "validate" {
  count           = local.github_connected ? 1 : 0
  project         = var.project_id
  location        = var.region
  name            = "validate-pr"
  description     = "Validates Terraform and Dataform on every pull request."
  service_account = "projects/${var.project_id}/serviceAccounts/${var.cloudbuild_sa_email}"

  repository_event_config {
    repository = google_cloudbuildv2_repository.intelia_warehouse[0].id
    pull_request {
      branch          = ".*"
      comment_control = "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
    }
  }

  filename = "cloudbuild-validate.yaml"
}

resource "google_cloudbuild_trigger" "deploy" {
  count           = local.github_connected ? 1 : 0
  project         = var.project_id
  location        = var.region
  name            = "deploy-main"
  description     = "Deploys Terraform and triggers Dataform full-refresh on push to main."
  service_account = "projects/${var.project_id}/serviceAccounts/${var.cloudbuild_sa_email}"

  repository_event_config {
    repository = google_cloudbuildv2_repository.intelia_warehouse[0].id
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild-deploy.yaml"
}
