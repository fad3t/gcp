provider "google" {
  region = "us-west1"
  zone   = "us-west1-b"
}

data "google_billing_account" "billing" {
  display_name = "My Billing Account"
}

## project
resource "google_project" "my_project" {
  name            = "fadet-project-1"
  project_id      = "fadet-project-1"
  billing_account = data.google_billing_account.billing.id
}

## enable compute API on project
resource "google_project_service" "my_project_compute_api" {
  project = google_project.my_project.project_id
  service = "compute.googleapis.com"
}

# ## default compute service account
# data "google_compute_default_service_account" "my_sa" {
#   project = google_project.my_project.project_id
# }
# 
# ## grant storage access to service account
# resource "google_project_iam_binding" "my_binding" {
#   project = google_project.my_project.project_id
#   role    = "roles/storage.objectAdmin"
#   members = [
#     "serviceAccount:${data.google_compute_default_service_account.my_sa.email}"
#   ]
# }
# 
# ## grant logging access to service account
# resource "google_project_iam_binding" "my_binding_log" {
#   project = google_project.my_project.project_id
#   role    = "roles/logging.admin"
#   members = [
#     "serviceAccount:${data.google_compute_default_service_account.my_sa.email}"
#   ]
# }
# 
# ## grant monitoring access to service account
# resource "google_project_iam_binding" "my_binding_monitor" {
#   project = google_project.my_project.project_id
#   role    = "roles/monitoring.admin"
#   members = [
#     "serviceAccount:${data.google_compute_default_service_account.my_sa.email}"
#   ]
# }

## storage bucket to store VM output
resource "google_storage_bucket" "my_bucket" {
  name    = "ex1-bucket"
  project = google_project.my_project.project_id
}

## VM
resource "google_compute_instance" "my_instance" {
  name         = "ex1-instance"
  project      = google_project.my_project.project_id
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  metadata_startup_script = file("boot.sh")
  metadata = {
    lab-logs-bucket = "gs://ex1-bucket"
  }
  service_account {
    scopes = [
      "logging-write",
      "monitoring-write",
      "storage-rw"
    ]
  }
  depends_on = [
    google_project_service.my_project_compute_api,
    google_storage_bucket.my_bucket
  ]
}
