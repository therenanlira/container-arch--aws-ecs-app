module "ecs_sales_worker" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ecs_service?ref=v1"

  network_values = data.terraform_remote_state.aws_vpc.outputs
  environment    = local.workspace.environment
  cluster_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.ecs_cluster_name
  project_name   = local.workspace.project_name

  service_name = "sales-worker-${data.aws_region.current.region}"
  service_port = local.workspace.service_port
  service_cpu  = local.workspace.service_cpu
  service_mem  = local.workspace.service_mem

  task_min   = local.workspace.task_min
  task_max   = local.workspace.task_max
  task_count = local.workspace.task_count

  container_image = "fidelissauro/sales-worker:latest"

  enable_lb = false

  service_healthcheck = local.workspace.service_healthcheck

  service_launch_type = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 50
    }
  ]

  service_hosts = [
  ]

  environment_variables = [
    {
      name  = "AWS_REGION"
      value = data.aws_region.current.region
    },
    {
      name  = "SSM_PARAMETER_STORE_STATE"
      value = module.ssm_parameter_sales_api.name
    },
    {
      name  = "DYNAMO_SALES_IDEMPOTENCY_TABLE"
      value = coalesce(one(module.dynamodb_idempotency[*].name), one(module.dynamodb_idempotency_replica[*].name))
    },
    {
      name  = "S3_SALES_BUCKET"
      value = module.sales_offload_datalake.bucket
    },
    {
      name  = "SQS_SALES_QUEUE"
      value = module.sqs_sales.id
    }
  ]

  force_delete = true
}
