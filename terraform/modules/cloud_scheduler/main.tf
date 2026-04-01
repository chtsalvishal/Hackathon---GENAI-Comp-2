# ---------------------------------------------------------------------------
# Cloud Scheduler — REMOVED.
# The full pipeline (bronze → silver → gold → AI) runs ONCE manually via
# CloudBuild on first deploy, then never again on a schedule.
# Delta ingestion is event-driven: Eventarc (GCS object.finalize) →
# delta-ingest-workflow → Dataform tag "delta" only.
# ---------------------------------------------------------------------------
