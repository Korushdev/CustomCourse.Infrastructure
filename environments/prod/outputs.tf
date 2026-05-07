output "vpc_id" {
  value = module.vpc.vpc_id
}

output "api_endpoint" {
  value = module.lambda_api.api_endpoint
}

output "api_custom_domain" {
  value = "https://api.${var.domain_name}"
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}

output "website_url" {
  value = "https://${var.domain_name}"
}

output "name_servers" {
  value = module.dns.name_servers
}
