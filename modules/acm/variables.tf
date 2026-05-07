variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the certificate"
  type        = string
}

variable "zone_id" {
  description = "Route 53 zone ID for validation"
  type        = string
}

variable "subject_alternative_names" {
  description = "SANs for the certificate"
  type        = list(string)
  default     = []
}
