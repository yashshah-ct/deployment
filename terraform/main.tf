terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks  = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.vpc_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pod_cidr
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.service_cidr
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = [var.subnet_cidr, var.pod_cidr, var.service_cidr]
}

resource "google_compute_firewall" "allow_ingress" {
  name    = "${var.vpc_name}-allow-ingress"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "9090", "3000", "15672"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_service_account" "gke_sa" {
  account_id   = "gke-${var.cluster_name}-sa"
  display_name = "GKE Cluster SA"
}

resource "google_project_iam_member" "gke_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "jenkins_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${var.jenkins_sa_email}"
}

resource "google_project_iam_member" "jenkins_artifact_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${var.jenkins_sa_email}"
}

resource "google_artifact_registry_repository" "registry" {
  location      = var.region
  repository_id = var.artifact_registry_name
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "registry_all_users" {
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.jenkins_sa_email}"
}

resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region
  network  = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  initial_node_count = 1
  remove_default_node_pool = true
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  enable_legacy_abac = true
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "all"
    }
  }
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
  release_channel {
    channel = "REGULAR"
  }
  node_config {
    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    machine_type = var.machine_type
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_container_node_pool" "primary" {
  name       = "primary-pool"
  location   = var.region
  cluster    = google_container_cluster.gke.name
  node_count = var.min_node_count
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  node_config {
    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    machine_type = var.machine_type
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
