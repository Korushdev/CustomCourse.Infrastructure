terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

module "vpc" {
  source               = "../../modules/vpc"
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  availability_zones   = var.availability_zones
  log_retention_days   = 7
}

module "assets_s3" {
  source      = "../../modules/s3"
  project_name = var.project_name
  environment = var.environment
  bucket_name = "generic-assets"
  is_website  = false
}

module "website_s3" {
  source      = "../../modules/s3"
  project_name = var.project_name
  environment = var.environment
  bucket_name = "angular-ssr-website"
  is_website  = true
}

module "lambda_api" {
  source             = "../../modules/lambda"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  assets_bucket_arn  = module.assets_s3.bucket_arn
  assets_bucket_id   = module.assets_s3.bucket_id
  website_bucket_arn = module.website_s3.bucket_arn
  website_bucket_id  = module.website_s3.bucket_id
  log_retention_days = 7
}

module "rds" {
  source                    = "../../modules/rds"
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.public_subnet_ids
  master_password           = var.db_password
  allowed_security_group_id = module.lambda_api.lambda_sg_id
}

module "cloudfront" {
  source                     = "../../modules/cloudfront"
  project_name               = var.project_name
  environment                = var.environment
  website_bucket_id          = module.website_s3.bucket_id
  website_bucket_arn         = module.website_s3.bucket_arn
  website_bucket_domain_name = module.website_s3.bucket_domain_name
  ssr_api_endpoint           = module.lambda_api.ssr_api_endpoint
}

module "cicd" {
  source                     = "../../modules/cicd"
  project_name               = var.project_name
  environment                = var.environment
  github_connection_arn      = var.github_connection_arn
  ui_repo_id                 = var.ui_repo_id
  api_repo_id                 = var.api_repo_id
  website_bucket_id          = module.website_s3.bucket_id
  lambda_function_name       = module.lambda_api.ssr_lambda_function_name
  cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
}
