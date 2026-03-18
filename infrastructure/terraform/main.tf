locals {
  project_root                   = abspath("${path.module}/../..")
  prometheus_config_path         = "${local.project_root}/monitoring/prometheus/prometheus.yml"
  prometheus_rules_path          = "${local.project_root}/monitoring/prometheus/rules"
  grafana_datasources_path       = "${local.project_root}/monitoring/grafana/provisioning/datasources"
  grafana_dashboard_config_path  = "${local.project_root}/monitoring/grafana/provisioning/dashboards"
  grafana_dashboards_path        = "${local.project_root}/monitoring/grafana/dashboards"
  jenkins_home_path              = "${local.project_root}/jenkins_home"
  jenkins_casc_path              = "${local.project_root}/jenkins/casc"
  local_application_context_path = "${local.project_root}/application/docker"
}

resource "docker_network" "monitoring" {
  name   = "${var.project_name}-${var.environment}"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.0.0/16"
    gateway = "172.20.0.1"
  }
}

resource "docker_volume" "prometheus_data" {
  name = "${var.project_name}-prometheus-data"
}

resource "docker_volume" "grafana_data" {
  name = "${var.project_name}-grafana-data"
}

resource "docker_image" "prometheus" {
  name         = "cgr.dev/chainguard/prometheus:latest"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = true
}

resource "docker_image" "jenkins" {
  name         = "${var.project_name}-jenkins:local"
  keep_locally = true

  build {
    context    = "${local.project_root}/jenkins"
    dockerfile = "Dockerfile"
    build_args = {
      TERRAFORM_VERSION = var.terraform_version
      TRIVY_VERSION     = var.trivy_version
    }
  }
}

resource "docker_image" "application" {
  name         = "${var.project_name}-app:local"
  keep_locally = true

  build {
    context    = local.local_application_context_path
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "prometheus" {
  name     = "prometheus"
  image    = docker_image.prometheus.image_id
  hostname = "prometheus"
  restart  = "unless-stopped"
  must_run = true
  wait     = true

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 9090
    external = var.prometheus_port
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  volumes {
    host_path      = local.prometheus_config_path
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  volumes {
    host_path      = local.prometheus_rules_path
    container_path = "/etc/prometheus/rules"
    read_only      = true
  }

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--storage.tsdb.retention.time=${var.monitoring_retention}",
    "--web.console.libraries=/usr/share/prometheus/console_libraries",
    "--web.console.templates=/usr/share/prometheus/consoles"
  ]

  labels {
    label = "com.tp.service"
    value = "prometheus"
  }
}

resource "docker_container" "grafana" {
  name     = "grafana"
  image    = docker_image.grafana.image_id
  hostname = "grafana"
  restart  = "unless-stopped"
  must_run = true
  wait     = true

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 3000
    external = var.grafana_port
  }

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  volumes {
    host_path      = local.grafana_datasources_path
    container_path = "/etc/grafana/provisioning/datasources"
    read_only      = true
  }

  volumes {
    host_path      = local.grafana_dashboard_config_path
    container_path = "/etc/grafana/provisioning/dashboards"
    read_only      = true
  }

  volumes {
    host_path      = local.grafana_dashboards_path
    container_path = "/var/lib/grafana/dashboards"
    read_only      = true
  }

  env = [
    "GF_SECURITY_ADMIN_USER=${var.grafana_admin_user}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_METRICS_ENABLED=true",
    "GF_AUTH_ANONYMOUS_ENABLED=false"
  ]

  depends_on = [docker_container.prometheus]

  labels {
    label = "com.tp.service"
    value = "grafana"
  }
}

resource "docker_container" "application" {
  name     = "monitoring-app"
  image    = docker_image.application.image_id
  hostname = "monitoring-app"
  restart  = "unless-stopped"
  must_run = true
  wait     = true

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 3001
    external = var.app_port
  }

  env = [
    "PORT=3001"
  ]

  labels {
    label = "com.tp.service"
    value = "monitoring-app"
  }
}

resource "docker_container" "jenkins" {
  name     = "jenkins"
  image    = docker_image.jenkins.image_id
  hostname = "jenkins"
  restart  = "unless-stopped"
  must_run = true
  wait     = true

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 8080
    external = var.jenkins_port
  }

  ports {
    internal = 50000
    external = var.jenkins_agent_port
  }

  env = [
    "JAVA_OPTS=-Djenkins.install.runSetupWizard=false",
    "CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/jenkins.yaml",
    "JENKINS_ADMIN_USER=${var.jenkins_admin_user}",
    "JENKINS_ADMIN_PASSWORD=${var.jenkins_admin_password}"
  ]

  volumes {
    host_path      = var.docker_socket_path
    container_path = "/var/run/docker.sock"
  }

  volumes {
    host_path      = local.jenkins_home_path
    container_path = "/var/jenkins_home"
  }

  volumes {
    host_path      = local.jenkins_casc_path
    container_path = "/var/jenkins_home/casc_configs"
    read_only      = true
  }

  volumes {
    host_path      = local.project_root
    container_path = "/workspace/tp-gitops-local"
  }

  depends_on = [
    docker_container.prometheus,
    docker_container.grafana,
    docker_container.application
  ]

  labels {
    label = "com.tp.service"
    value = "jenkins"
  }
}

