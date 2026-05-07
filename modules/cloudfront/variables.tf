variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "website_bucket_id" {
  description = "ID of the website S3 bucket"
  type        = string
}

variable "website_bucket_arn" {
  description = "ARN of the website S3 bucket"
  type        = string
}

variable "website_bucket_domain_name" {
  description = "Domain name of the website S3 bucket"
  type        = string
}

variable "ssr_api_endpoint" {
  description = "Endpoint of the SSR API Gateway"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
  default     = ""
}
