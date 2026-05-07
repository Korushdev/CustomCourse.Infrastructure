variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string
}

variable "is_website" {
  description = "Whether the bucket is for a website"
  type        = bool
  default     = false
}
