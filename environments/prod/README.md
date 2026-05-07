# Infrastructure Starter Project

This project contains the Terraform infrastructure for a generic starter project, supporting multiple environments (dev, uat, prod).

## Project Structure

- `modules/`: Reusable Terraform modules.
  - `vpc/`: Network infrastructure (VPC, public/private subnets, NAT Gateway).
  - `s3/`: Generic S3 buckets and website hosting buckets.
  - `rds/`: Aurora Serverless Postgres database.
  - `lambda/`: Lambda API with API Gateway and S3 access.
  - `cloudfront/`: CloudFront distribution for the website.
- `environments/`: Environment-specific configurations.
  - `dev/`, `uat/`, `prod/`: Terraform root modules for each environment.

## Infrastructure Highlights

- **Network**: VPC with public subnets for public-facing resources and private subnets for internal services. NAT Gateway provides outbound internet access for private subnets.
- **Database**: Aurora Serverless Postgres (v2) for scalable data storage.
- **API**: Lambda-based API behind an HTTP API Gateway, with permissions to access an S3 asset bucket and logging to CloudWatch.
- **Frontend**: Angular SSR project hosted on S3 and served via CloudFront for global content delivery.
- **Logging**: All CloudWatch log groups have a configured retention period of 7 days.

## Getting Started

1. Navigate to the desired environment directory:
   ```bash
   cd environments/dev
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Provide required variables (e.g., `db_password`) in a `terraform.tfvars` file or via environment variables.

4. Plan and apply the infrastructure:
   ```bash
   terraform plan
   terraform apply
   ```

## Requirements

- Terraform v1.0+
- AWS CLI configured with appropriate permissions.
