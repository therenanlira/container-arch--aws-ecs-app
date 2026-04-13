module "ecs_service" {
  source = "../../container-arch--aws-ecs-module/ecs_service"

  network_conf = data.terraform_remote_state.aws_vpc.outputs
  cluster_name = data.terraform_remote_state.aws_ecs_cluster.outputs.ecs_cluster_name

  service_name = local.workspace.service_name
  service_port = local.workspace.service_port
  service_cpu  = local.workspace.service_cpu
  service_mem  = local.workspace.service_mem
}
