variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Project name used in Docker resources"
  type        = string
  default     = "gitops-monitoring"
}

variable "docker_host" {
  description = "Docker daemon socket used by the Terraform provider"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "docker_socket_path" {
  description = "Host path of the Docker socket mounted into Jenkins"
  type        = string
  default     = "/var/run/docker.sock"
}

variable "monitoring_retention" {
  description = "Prometheus metrics retention"
  type        = string
  default     = "15d"
}

variable "prometheus_port" {
  description = "Prometheus host port"
  type        = number
  default     = 9090
}

variable "grafana_port" {
  description = "Grafana host port"
  type        = number
  default     = 3000
}

variable "jenkins_port" {
  description = "Jenkins web host port"
  type        = number
  default     = 8080
}

variable "jenkins_agent_port" {
  description = "Jenkins agent host port"
  type        = number
  default     = 50000
}

variable "app_port" {
  description = "Demo application host port"
  type        = number
  default     = 3001
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "gitops2026"
}

variable "jenkins_admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
  default     = "Admin123!2026"
}

variable "terraform_version" {
  description = "Terraform version bundled in the Jenkins image"
  type        = string
  default     = "1.6.6"
}

variable "trivy_version" {
  description = "Trivy version bundled in the Jenkins image"
  type        = string
  default     = "0.69.3"
}
