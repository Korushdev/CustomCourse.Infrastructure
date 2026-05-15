variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_ids" {
  description = "Public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "github_connection_arn" {
  description = "ARN of the CodeStar Connection to GitHub"
  type        = string
}

variable "ui_repo_id" {
  description = "GitHub repository ID for the UI"
  type        = string
}

variable "api_repo_id" {
  description = "GitHub repository ID for the API"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
}

variable "api_secret_name" {
  description = "The name of the api secret"
  type = string
}

variable "mail_spf_record_name" {
  description = "mail. txt record used for mailgun SPF validation"
  type        = string
}

variable "mail_spf_record_value" {
  description = "mail. txt record used for mailgun SPF validation"
  type        = string
}

variable "mail_dkim_record_name" {
  description = "mail. txt record used for mailgun DKIM validation"
  type        = string
}

variable "mail_dkim_record_value" {
  description = "mail. txt record used for mailgun DKIM validation"
  type        = string
}