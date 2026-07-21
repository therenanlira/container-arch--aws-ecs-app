module "test_parameter_store" {
  # source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ssm_parameter_store?ref=v1"
  source = "../../container-arch--aws-modules/ssm_parameter_store"

  service_name = local.workspace.service_name
  value        = "abc123456"
}
