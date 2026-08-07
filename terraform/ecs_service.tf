module "ecs_service" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ecs_service?ref=v1"

  cluster_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.ecs_cluster_name
  project_name   = local.workspace.project_name
  network_values = data.terraform_remote_state.aws_vpc.outputs

  service_name = local.workspace.service_name
  service_port = local.workspace.service_port
  service_cpu  = local.workspace.service_cpu
  service_mem  = local.workspace.service_mem

  task_min   = local.workspace.task_min
  task_max   = local.workspace.task_max
  task_count = local.workspace.task_count

  service_healthcheck = local.workspace.service_healthcheck
  service_launch_type = local.workspace.service_launch_type

  service_hosts    = local.workspace.service_hosts
  service_listener = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_listener_arn

  scale_type              = local.workspace.scale_type
  scale_tracking_cpu      = local.workspace.scale_tracking_cpu
  scale_tracking_requests = local.workspace.scale_tracking_requests
  scale_out_cpu           = local.workspace.scale_out_cpu
  scale_in_cpu            = local.workspace.scale_in_cpu

  efs_volumes = [
    {
      volume_name      = module.efs.name
      file_system_id   = module.efs.id
      file_system_root = "/"
      mount_point      = "/mnt/efs"
      read_only        = false
    }
  ]

  alb_arn      = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_arn
  alb_dns_name = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_dns_name
  alb_zone_id  = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_zone_id

  dns_zone_id = data.terraform_remote_state.aws_vpc.outputs.dns_zone_id
  dns_name    = data.terraform_remote_state.aws_vpc.outputs.dns_name

  service_discovery_namespace = data.terraform_remote_state.aws_ecs_cluster.outputs.cloudmap_id

  capabilities          = local.workspace.capabilities
  environment_variables = local.workspace.env_vars
  secrets = [
    {
      name      = "VALUE_FROM_SSM_PARAMETER_STORE"
      valueFrom = module.test_parameter_store.arn
    },
    {
      name      = "VALUE_FROM_SSM_SECRETS_MANAGER"
      valueFrom = module.test_secrets_manager.arn
    }
  ]
}
