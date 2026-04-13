locals {
  parameter_resource_name = "${var.cluster_name}--${var.service_name}"
}

resource "aws_ssm_parameter" "parameter" {
  name  = "${local.parameter_resource_name}--parameter"
  type  = "String"
  value = "Parameter Store v1"
}
