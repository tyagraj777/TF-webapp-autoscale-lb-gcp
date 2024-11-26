provider "google" {
  project = "cool-agility-442507-c5"
  region  = "us-central1"
}

resource "google_compute_instance_template" "web_template" {
  name         = "web-template"
  machine_type = "e2-micro"
  disk {
    boot         = true
    auto_delete  = true
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
  }
  network_interface {
    network = "default"
    access_config {}
  }
  metadata_startup_script = <<EOT
#!/bin/bash
sudo apt update
sudo apt install -y apache2
sudo systemctl start apache2
EOT
}

resource "google_compute_target_pool" "web_pool" {
  name = "web-pool"
}

resource "google_compute_instance_group_manager" "web_igm" {
  name               = "web-igm"
  base_instance_name = "web-instance"
  target_size        = 1
  target_pools       = [google_compute_target_pool.web_pool.self_link]
  zone               = "us-central1-a" # Replace with your desired zone

  version {
    instance_template = google_compute_instance_template.web_template.id
  }
}

resource "google_compute_http_health_check" "health_check" {
  name               = "http-health-check"
  request_path       = "/"
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2
}

resource "google_compute_forwarding_rule" "http_lb" {
  name       = "http-lb"
  target     = google_compute_target_pool.web_pool.self_link
  port_range = "80"
  ip_protocol = "TCP"
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
}
