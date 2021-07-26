provider "google" {
  region  = "us-west1"
  zone    = "us-west1-b"
  project = "fadet-project-1"
}

## service accounts
resource "google_service_account" "ex2_fe_sa" {
  account_id = "ex2-fe-sa"
}

resource "google_service_account" "ex2_be_sa" {
  account_id = "ex2-be-sa"
}

## instance template
resource "google_compute_instance_template" "ex2_fe_template" {
  name         = "ex2-fe-template"
  machine_type = "f1-micro"

  tags = ["allow-ssh"]
  network_interface {
    subnetwork = google_compute_subnetwork.ex2_subnet.id
    access_config {
    }
  }
  disk {
    source_image = "debian-cloud/debian-10"
    auto_delete  = true
    boot         = true
  }
  service_account {
    email  = google_service_account.ex2_fe_sa.email
    scopes = []
  }
}

resource "google_compute_instance_template" "ex2_be_template" {
  name         = "ex2-be-template"
  machine_type = "f1-micro"

  tags = ["allow-ssh"]
  network_interface {
    subnetwork = google_compute_subnetwork.ex2_subnet.id
    access_config {
    }
  }
  disk {
    source_image = "debian-cloud/debian-10"
    auto_delete  = true
    boot         = true
  }
  service_account {
    email  = google_service_account.ex2_be_sa.email
    scopes = []
  }
}

## instance group
resource "google_compute_instance_group_manager" "ex2_fe_igm" {
  name               = "ex2-fe-igm"
  base_instance_name = "ex2-fe"
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.ex2_fe_template.id
  }
}

resource "google_compute_instance_group_manager" "ex2_be_igm" {
  name               = "ex2-be-igm"
  base_instance_name = "ex2-be"
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.ex2_be_template.id
  }
}

## custom VPC
resource "google_compute_network" "ex2_vpc" {
  name                    = "ex2-vpc"
  auto_create_subnetworks = false
}

## subnets
resource "google_compute_subnetwork" "ex2_subnet" {
  name          = "ex2-subnet"
  ip_cidr_range = "10.10.10.0/24"
  network       = google_compute_network.ex2_vpc.id
}

## firewall rules
resource "google_compute_firewall" "ex2_fe_allow_icmp" {
  name                    = "ex2-fe-allow-icmp"
  network                 = google_compute_network.ex2_vpc.id
  target_service_accounts = [google_service_account.ex2_fe_sa.email]
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "ex2_be_allow_fe" {
  name                    = "ex2-be-allow-fe"
  network                 = google_compute_network.ex2_vpc.id
  target_service_accounts = [google_service_account.ex2_be_sa.email]
  source_service_accounts = [google_service_account.ex2_fe_sa.email]
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "ex2_be_deny_out" {
  name                    = "ex2-be-deny-out"
  network                 = google_compute_network.ex2_vpc.id
  target_service_accounts = [google_service_account.ex2_be_sa.email]
  direction               = "EGRESS"
  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "ex2_allow_ssh" {
  name        = "ex2-allow-ssh"
  network     = google_compute_network.ex2_vpc.id
  target_tags = ["allow-ssh"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
