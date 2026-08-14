# SQS

module "sqs_sales" {
  count  = local.workspace.is_central ? 1 : 0
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

  create_subscription = local.workspace.is_central || local.has_central

  queue_arn = (local.workspace.is_central ?
    one(module.sqs_sales[*].arn) :
    try(one(data.terraform_remote_state.central[*].outputs.sqs_sales_arn), null)
  )
}
