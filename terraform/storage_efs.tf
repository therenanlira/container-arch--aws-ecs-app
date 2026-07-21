module "efs" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//efs_storage?ref=v1"

  service_name   = local.workspace.service_name
  network_values = data.terraform_remote_state.aws_vpc.outputs
}
