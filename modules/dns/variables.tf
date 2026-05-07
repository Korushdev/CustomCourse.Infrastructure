variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID"
  type        = string
}

variable "api_gateway_domain_name" {
  description = "API Gateway custom domain name"
  type        = string
}

variable "api_gateway_hosted_zone_id" {
  description = "API Gateway hosted zone ID"
  type        = string
}
