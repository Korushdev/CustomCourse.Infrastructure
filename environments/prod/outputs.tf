output "vpc_id" {
  value = module.vpc.vpc_id
}

output "api_endpoint" {
  value = module.lambda_api.api_endpoint
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}

output "rds_endpoint" {
  value = module.rds.rds_cluster_endpoint
}
