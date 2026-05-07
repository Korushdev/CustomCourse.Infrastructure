resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-${var.environment}-lambda-sg"
  description = "Security group for Lambda"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "lambda_s3" {
  name        = "${var.project_name}-${var.environment}-lambda-s3-policy"
  description = "Allow Lambda to put/get objects in S3"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject", "s3:GetObject"]
        Effect   = "Allow"
        Resource = "${var.assets_bucket_arn}/*"
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "${var.website_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3.arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-api"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Dummy deployment package for Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source {
    content  = "exports.handler = async (event) => { return { statusCode: 200, body: 'Hello' }; };"
    filename = "index.js"
  }
}

resource "aws_lambda_function" "api" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project_name}-${var.environment}-api"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "api::api.LambdaEntryPoint::FunctionHandlerAsync"
  runtime       = "dotnet10"
  architectures = ["x86_64"]

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      S3_BUCKET = var.assets_bucket_id
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_vpc_access, aws_cloudwatch_log_group.lambda]
}

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-${var.environment}-http-api"
  protocol_type = "HTTP"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      sourceIp       = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api-gw/${var.project_name}-${var.environment}-http-api"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_apigatewayv2_domain_name" "api" {
  count       = var.api_domain_name != "" ? 1 : 0
  domain_name = var.api_domain_name

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_api_mapping" "api" {
  count       = var.api_domain_name != "" ? 1 : 0
  api_id      = aws_apigatewayv2_api.main.id
  domain_name = aws_apigatewayv2_domain_name.api[0].id
  stage       = aws_apigatewayv2_stage.main.id
}

resource "aws_lambda_function" "ssr" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project_name}-${var.environment}-ssr"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "server.handler"
  runtime       = "nodejs24.x"
  timeout       = 10
  memory_size   = 512

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      NG_ALLOWED_HOSTS = replace(aws_apigatewayv2_api.ssr.api_endpoint, "https://", "")
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_vpc_access, aws_cloudwatch_log_group.ssr]
}

resource "aws_cloudwatch_log_group" "ssr" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-ssr"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_api" "ssr" {
  name          = "${var.project_name}-${var.environment}-ssr-api"
  protocol_type = "HTTP"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_stage" "ssr" {
  api_id      = aws_apigatewayv2_api.ssr.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_integration" "ssr" {
  api_id                 = aws_apigatewayv2_api.ssr.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ssr.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "ssr" {
  api_id    = aws_apigatewayv2_api.ssr.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.ssr.id}"
}

resource "aws_apigatewayv2_route" "ssr_root" {
  api_id    = aws_apigatewayv2_api.ssr.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.ssr.id}"
}

resource "aws_lambda_permission" "ssr_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ssr.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ssr.execution_arn}/*/*"
}

output "ssr_api_endpoint" {
  value = aws_apigatewayv2_api.ssr.api_endpoint
}

output "ssr_lambda_function_name" {
  value = aws_lambda_function.ssr.function_name
}

output "api_lambda_function_name" {
  value = aws_lambda_function.api.function_name
}

output "lambda_sg_id" {
  value = aws_security_group.lambda.id
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.main.api_endpoint
}

output "api_gateway_domain_name" {
  value = var.api_domain_name != "" ? aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].target_domain_name : ""
}

output "api_gateway_hosted_zone_id" {
  value = var.api_domain_name != "" ? aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].hosted_zone_id : ""
}
