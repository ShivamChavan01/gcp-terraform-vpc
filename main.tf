provider "google" {
    project = "terraform-vpc-461207"
    region  = var.region
}

variable "region" {
  description = ""
  type        = string
  default     = "us-central1"
  
}


resource "google_compute_network" "vpc_network" {
    name                    = "my-vpc"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public_subnet" {
    name          = "public-subnet"
    ip_cidr_range = "10.0.1.0/24"
    region        = var.region
    network       = google_compute_network.vpc_network.id
    private_ip_google_access = true
}

resource "google_compute_subnetwork" "private_subnet" {
    name          = "private-subnet"
    ip_cidr_range = "10.0.2.0/24"
    region        = var.region
    network       = google_compute_network.vpc_network.id
    private_ip_google_access = true
}

resource "google_compute_router" "nat_router" {
    name    = "nat-router"
    network = google_compute_network.vpc_network.id
    region  = var.region
}

resource "google_compute_router_nat" "nat_gw" {
    name                               = "nat-gateway"
    router                             = google_compute_router.nat_router.name
    region                             = var.region
    nat_ip_allocate_option             = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    subnetwork {
        name                    = google_compute_subnetwork.private_subnet.name
        source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
}

resource "google_compute_firewall" "allow_public_ingress" {
    name    = "allow-public-ingress"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["22", "80", "443"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags   = ["public"]
}

resource "google_compute_firewall" "allow_private_internal" {
    name    = "allow-private-internal"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "all"
    }

    source_ranges = ["10.0.0.0/16"]
}