data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket           = lower(format("%s-%s-%s-an", "${var.project_name}-${var.environment}-build", data.aws_caller_identity.current.account_id, data.aws_region.current.region))
  bucket_namespace = "account-regional"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*",
          "arn:aws:s3:::${var.website_bucket_id}",
          "arn:aws:s3:::${var.website_bucket_id}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "arn:aws:s3:::${var.website_bucket_id}"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "lambda:UpdateFunctionCode"
        ]
        Resource = [
          "arn:aws:lambda:*:*:function:${var.ssr_lambda_function_name}",
          "arn:aws:lambda:*:*:function:${var.api_lambda_function_name}"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-${var.environment}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "codestar-connections:UseConnection"
        ]
        Resource = [var.github_connection_arn]
      },
      {
        Effect   = "Allow"
        Action   = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# CodeBuild Projects
resource "aws_codebuild_project" "ui_build" {
  name          = "${var.project_name}-${var.environment}-ui-build"
  description   = "Builds the UI and deploys to S3"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:8.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    
    environment_variable {
      name  = "BUCKET_ID"
      value = var.website_bucket_id
    }
    
    environment_variable {
      name  = "CLOUDFRONT_DISTRIBUTION_ID"
      value = var.cloudfront_distribution_id
    }
    
    environment_variable {
      name  = "SSR_LAMBDA_FUNCTION_NAME"
      value = var.ssr_lambda_function_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2
      phases:
        install:
          runtime-versions:
            nodejs: 24
        pre_build:
          commands:
            - npm install
        build:
          commands:
            - npm run build
        post_build:
          commands:
            - aws s3 sync dist/FrontEnd/browser s3://$BUCKET_ID/ --delete
            - cd dist/FrontEnd/server && zip -r ../../../lambda-ssr.zip . && cd ../../..
            - aws lambda update-function-code --function-name $SSR_LAMBDA_FUNCTION_NAME --zip-file fileb://lambda-ssr.zip
            - aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths "/*"
    EOF
  }
}

resource "aws_codebuild_project" "api_build" {
  name          = "${var.project_name}-${var.environment}-api-build"
  description   = "Builds the .NET 10 API and deploys to Lambda"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:8.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    
    environment_variable {
      name  = "API_LAMBDA_FUNCTION_NAME"
      value = var.api_lambda_function_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2
      phases:
        install:
          commands:
            - wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
            - chmod +x dotnet-install.sh
            - ./dotnet-install.sh --channel 10.0
            - export PATH="$PATH:/root/.dotnet"
        build:
          commands:
            - dotnet publish src/WebApi/WebApi.csproj -c Release -o out
            - wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O out/global-bundle.pem
        post_build:
          commands:
            - cd out && zip -r ../lambda-api.zip . && cd ..
            - aws lambda update-function-code --function-name $API_LAMBDA_FUNCTION_NAME --zip-file fileb://lambda-api.zip
    EOF
  }
}

# CodePipelines
resource "aws_codepipeline" "ui_pipeline" {
  name     = "${var.project_name}-${var.environment}-ui-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.ui_repo_id
        BranchName       = var.ui_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ui_build.name
      }
    }
  }
}

resource "aws_codepipeline" "api_pipeline" {
  name     = "${var.project_name}-${var.environment}-api-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.api_repo_id
        BranchName       = var.api_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.api_build.name
      }
    }
  }
}