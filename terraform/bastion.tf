module "bastion" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ec2_instance?ref=v1"

  project_name   = local.workspace.project_name
  service_name   = "bastion"
  network_values = data.terraform_remote_state.aws_vpc.outputs

  instance_type = "t4g.micro"
}
