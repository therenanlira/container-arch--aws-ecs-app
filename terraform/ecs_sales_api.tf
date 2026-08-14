module "ecs_sales_api" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ecs_service?ref=v1"

  network_values = data.terraform_remote_state.aws_vpc.outputs
  environment    = local.workspace.environment
  cluster_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.ecs_cluster_name
  project_name   = local.workspace.project_name

  service_name = "sales-api-${data.aws_region.current.region}"
  service_port = local.workspace.service_port
  service_cpu  = local.workspace.service_cpu
  service_mem  = local.workspace.service_mem

  task_min   = local.workspace.task_min
  task_max   = local.workspace.task_max
  task_count = local.workspace.task_count

  container_image = "fidelissauro/sales-rest-api:latest"

  service_listener = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_listener_arn
  alb_arn          = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_arn
  alb_dns_name     = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_dns_name
  alb_zone_id      = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_zone_id


  dns_zone_id = data.terraform_remote_state.aws_vpc.outputs.dns_zone_id
  dns_name    = data.terraform_remote_state.aws_vpc.outputs.dns_name
  dns_weight  = local.workspace.dns_weight

  service_healthcheck = local.workspace.service_healthcheck

  service_launch_type = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 50
    }
  ]

  service_hosts = [
    "sales.container-arch.internal.com"
  ]

  environment_variables = [
    {
      name  = "AWS_REGION"
      value = data.aws_region.current.region
    },
    {
      name  = "SNS_SALES_PROCESSING_TOPIC"
      value = module.sns_sales.arn
    },
    {
      name  = "SSM_PARAMETER_STORE_STATE"
      value = module.ssm_parameter_sales_api.name
    },
    {
      name  = "DYNAMO_SALES_TABLE"
      value = coalesce(one(module.dynamodb_sales[*].name), one(module.dynamodb_sales_replica[*].name))
    }
  ]

  force_delete = true
}

module "ssm_parameter_sales_api" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ssm_parameter_store?ref=v1"

  service_name = "sales-api"
  value        = local.workspace.is_central ? "ACTIVE" : "PASSIVE"
}
