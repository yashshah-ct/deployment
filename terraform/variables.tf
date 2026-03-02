variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "cluster_name" {
  type    = string
  default = "main-cluster"
}

variable "vpc_name" {
  type    = string
  default = "main-vpc"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/20"
}

variable "pod_cidr" {
  type    = string
  default = "10.4.0.0/14"
}

variable "service_cidr" {
  type    = string
  default = "10.8.0.0/20"
}

variable "min_node_count" {
  type    = number
  default = 1
}

variable "max_node_count" {
  type    = number
  default = 5
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "artifact_registry_name" {
  type    = string
  default = "microservices"
}

variable "jenkins_sa_email" {
  type = string
}

variable "environment" {
  type    = string
  default = "production"
}
