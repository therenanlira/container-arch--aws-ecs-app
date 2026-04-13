locals {
  secretmanager_resource_name = "${var.cluster_name}--${var.service_name}"
}

resource "aws_secretsmanager_secret" "secret" {
  name = "${local.secretmanager_resource_name}--secret"
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = "Secret Manager v1"
}
