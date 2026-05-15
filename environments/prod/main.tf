terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

module "dns" {
  source                    = "../../modules/dns"
  project_name              = var.project_name
  environment               = var.environment
  domain_name               = var.domain_name
  cloudfront_domain_name    = module.cloudfront.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id
  api_gateway_domain_name   = module.lambda_api.api_gateway_domain_name
  api_gateway_hosted_zone_id = module.lambda_api.api_gateway_hosted_zone_id
  mail_spf_record_name = var.mail_spf_record_name
  mail_spf_record_value = var.mail_spf_record_value
  mail_dkim_record_name = var.mail_dkim_record_name
  mail_dkim_record_value = var.mail_dkim_record_value
}

module "acm_cloudfront" {
  source                    = "../../modules/acm"
  project_name              = var.project_name
  environment               = var.environment
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  zone_id                   = module.dns.zone_id
}

module "acm_api" {
  source       = "../../modules/acm"
  project_name = var.project_name
  environment  = var.environment
  domain_name  = "api.${var.domain_name}"
  zone_id      = module.dns.zone_id
}

module "assets_s3" {
  source      = "../../modules/s3"
  project_name = var.project_name
  environment = var.environment
  bucket_name = "assets"
  is_website  = false
}

module "website_s3" {
  source      = "../../modules/s3"
  project_name = var.project_name
  environment = var.environment
  bucket_name = "angular"
  is_website  = true
}

module "lambda_api" {
  source             = "../../modules/lambda"
  project_name       = var.project_name
  environment        = var.environment
  assets_bucket_arn  = module.assets_s3.bucket_arn
  assets_bucket_id   = module.assets_s3.bucket_id
  website_bucket_arn = module.website_s3.bucket_arn
  subnet_ids = var.public_subnet_ids
  log_retention_days = 7
  api_domain_name    = "api.${var.domain_name}"
  api_handler = "WebApi"
  certificate_arn    = module.acm_api.certificate_arn
  api_secret_name   = var.api_secret_name
}

module "rds" {
  source                    = "../../modules/rds"
  project_name              = var.project_name
  environment               = var.environment
  master_password           = data.aws_secretsmanager_secret_version.db_password.secret_string
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
  domain_name                = var.domain_name
  certificate_arn            = module.acm_cloudfront.certificate_arn
}

module "cicd" {
  source                     = "../../modules/cicd"
  project_name               = var.project_name
  environment                = var.environment
  github_connection_arn      = var.github_connection_arn
  ui_repo_id                 = var.ui_repo_id
  api_repo_id                = var.api_repo_id
  website_bucket_id          = module.website_s3.bucket_id
  ssr_lambda_function_name   = module.lambda_api.ssr_lambda_function_name
  api_lambda_function_name   = module.lambda_api.api_lambda_function_name
  cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
}
