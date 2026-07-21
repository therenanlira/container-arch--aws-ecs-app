module "test_parameter_store" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ssm_parameter_store?ref=v1"

  service_name = local.workspace.service_name
  value        = "abc123456"
}
