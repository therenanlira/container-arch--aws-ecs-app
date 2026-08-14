# SQS

module "sqs_sales" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//sqs_queue?ref=v1"

  environment  = local.workspace.environment
  project_name = local.workspace.project_name
  service_name = local.workspace.service_name

  publisher_regions = [for ws in var.workspaces : ws.aws_region]

  processing_config = {
    queue_suffix                  = "sales"
    delay_seconds                 = 0
    max_message_size              = 262144
    message_retention_seconds     = 86400
    receive_wait_time_seconds     = 10
    visibility_timeout_seconds    = 60
    dlq_redrive_max_receive_count = 4
  }
}

# SNS

module "sns_sales" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//sns_topic?ref=v1"

  environment  = local.workspace.environment
  project_name = local.workspace.project_name
  service_name = local.workspace.service_name

  topic_suffix = "sales"

  sqs_arn = merge(
    { (local.workspace.aws_region) = module.sqs_sales.arn },
    local.has_central ? { (local.workspace.central_region) = data.terraform_remote_state.central[0].outputs.sqs_sales_arn } : {}
  )
}

module "sns_sales_cross_subscription" {
  count  = !local.workspace.is_central && local.has_central ? 1 : 0
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//sns_topic?ref=v1"

  providers = { aws = aws.central }

  environment  = local.workspace.environment
  project_name = local.workspace.project_name
  service_name = local.workspace.service_name

  create_topic = false

  topic_suffix = "sales"
  topic_arn    = data.terraform_remote_state.central[0].outputs.sns_sales_arn

  sqs_arn = {
    (local.workspace.aws_region) = module.sqs_sales.arn
  }
}
