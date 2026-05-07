variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_connection_arn" {
  description = "ARN of the CodeStar Connection to GitHub"
  type        = string
}

variable "ui_repo_id" {
  description = "GitHub repository ID for the UI (e.g., owner/repo)"
  type        = string
}

variable "ui_branch" {
  description = "Branch for the UI repository"
  type        = string
  default     = "main"
}

variable "website_bucket_id" {
  description = "S3 bucket ID for the website"
  type        = string
}

variable "ssr_lambda_function_name" {
  description = "Name of the SSR Lambda function to update"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  type        = string
}
