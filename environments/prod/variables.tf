variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "starter"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
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
