module "ecs_service" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ecs_service?ref=v1"

  cluster_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.ecs_cluster_name
  project_name   = local.workspace.project_name
  network_values = data.terraform_remote_state.aws_vpc.outputs

  service_name = local.workspace.service_name
  service_port = local.workspace.service_port
  service_cpu  = local.workspace.service_cpu
  service_mem  = local.workspace.service_mem

  service_healthcheck = local.workspace.service_healthcheck
  service_launch_type = local.workspace.service_launch_type
  service_task_count  = local.workspace.service_task_count

  service_hosts    = local.workspace.service_hosts
  service_listener = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_listener_arn

  scale_type              = local.workspace.scale_type
  scale_tracking_cpu      = local.workspace.scale_tracking_cpu
  scale_tracking_requests = local.workspace.scale_tracking_requests
  task_min                = local.workspace.task_min
  task_max                = local.workspace.task_max
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

  alb_arn = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_arn

  capabilities          = local.workspace.capabilities
  environment_variables = local.workspace.env_vars
}
