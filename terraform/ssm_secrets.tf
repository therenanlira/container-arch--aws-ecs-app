module "test_secrets_manager" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ssm_parameter_store?ref=v1"

  service_name = "${local.workspace.service_name}-test2"
  value        = "abc123456"
}
