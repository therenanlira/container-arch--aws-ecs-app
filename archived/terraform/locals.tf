locals {
  private_subnets = [
    data.aws_ssm_parameter.private_subnet_1a.value,
    data.aws_ssm_parameter.private_subnet_1b.value,
    data.aws_ssm_parameter.private_subnet_1c.value
  ]
}