variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "assets_bucket_arn" {
  description = "ARN of the assets S3 bucket"
  type        = string
}

variable "assets_bucket_id" {
  description = "ID of the assets S3 bucket"
  type        = string
}

variable "website_bucket_id" {
  description = "ID of the website S3 bucket"
  type        = string
  default     = ""
}

variable "website_bucket_arn" {
  description = "ARN of the website S3 bucket"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "api_domain_name" {
  description = "Custom domain name for API"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for API"
  type        = string
  default     = ""
}
