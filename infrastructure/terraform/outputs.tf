output "network_name" {
  description = "Docker network name"
  value       = docker_network.monitoring.name
}

output "service_urls" {
  description = "Local access URLs"
  value = {
    prometheus = "http://localhost:${var.prometheus_port}"
    grafana    = "http://localhost:${var.grafana_port}"
    jenkins    = "http://localhost:${var.jenkins_port}"
    app        = "http://localhost:${var.app_port}"
  }
}

output "grafana_admin_user" {
  description = "Grafana admin user"
  value       = var.grafana_admin_user
}

output "jenkins_admin_user" {
  description = "Jenkins admin user"
  value       = var.jenkins_admin_user
}

