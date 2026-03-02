output "cluster_name" {
  value = google_container_cluster.gke.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.gke.endpoint
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = google_container_cluster.gke.master_auth[0].cluster_ca_certificate
  sensitive = true
}

output "region" {
  value = var.region
}

output "project_id" {
  value = var.project_id
}

output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}"
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}
