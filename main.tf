variable "project" {
}

variable "region" {
}

variable "zone" {
}

terraform {
  backend "gcs" {
    bucket = "klaraworks-tfstate"
    path   = "prototip-1.tfstate"
    credentials = "../../secrets/klaraworks-tfstate.json"
  }
}

provider "google" {
  credentials = file("../../secrets/prototip-1-terraformer.json")
  project     = var.project
  region      = var.region
  version     = "~> 3.0.0"
}

resource "google_compute_global_address" "static" {
  name = "prototip-1"
}

resource "google_dns_managed_zone" "zone" {
  name = "prototip-1"
  dns_name = "prototip-1.kirisaki.dev."
}

resource "google_dns_record_set" "a" {
  name = google_dns_managed_zone.zone.dns_name
  managed_zone = google_dns_managed_zone.zone.name
  type = "A"
  ttl = 300
  rrdatas = [google_compute_global_address.static.address]
}

resource "google_container_cluster" "primary"{
  name = "prototip-1-cluster"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count = 1
}

resource "google_container_node_pool" "primary_nodes" {
  name = "prototip-1-pool"
  location = var.zone
  cluster = google_container_cluster.primary.name
  node_count = 1

  management {
    auto_repair = true
  }

  node_config {
    machine_type = "e2-micro"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "prototip-1-preemptible"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 2

  management {
    auto_repair = true
  }

  node_config {
    preemptible  = true
    machine_type = "e2-micro"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
