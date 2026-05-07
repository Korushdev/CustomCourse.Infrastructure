data "aws_secretsmanager_secret" "db_password-by-arn" {
  name = "/customcourse/prod/aurora/masterpassword"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id            = data.aws_secretsmanager_secret.db_password-by-arn.id
}