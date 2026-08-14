# DynamoDB Idempotency

module "dynamodb_idempotency" {
  count  = local.workspace.is_central ? 1 : 0
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//dynamodb_table?ref=v1"

  project_name = local.workspace.project_name
  environment  = local.workspace.environment
  service_name = local.workspace.service_name

  dynamodb_values = {
    table_suffix            = "idempotency"
    billing_mode            = "PROVISIONED"
    point_in_time_recovery  = false
    recovery_period_in_days = 7

    read_min                 = 10
    read_max                 = 100
    read_autoscale_threshold = 80

    write_min                 = 10
    write_max                 = 100
    write_autoscale_threshold = 80
  }
}

module "dynamodb_idempotency_replica" {
  count  = !local.workspace.is_central && local.has_central ? 1 : 0
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//dynamodb_table_replication?ref=v1"

  global_table_arn = try(data.terraform_remote_state.central[0].outputs.dynamodb_idempotency, null)
}

# DynamoDB Sales

module "dynamodb_sales" {
  count  = local.workspace.is_central ? 1 : 0
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//dynamodb_table?ref=v1"

  project_name = local.workspace.project_name
  environment  = local.workspace.environment
  service_name = local.workspace.service_name

  dynamodb_values = {
    table_suffix            = "sales"
    billing_mode            = "PROVISIONED"
    point_in_time_recovery  = false
    recovery_period_in_days = 7

    read_min                 = 10
    read_max                 = 100
    read_autoscale_threshold = 80

    write_min                 = 10
    write_max                 = 100
    write_autoscale_threshold = 80
  }
}

module "dynamodb_sales_replica" {
  count  = !local.workspace.is_central && local.has_central ? 1 : 0
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//dynamodb_table_replication?ref=v1"

  global_table_arn = try(data.terraform_remote_state.central[0].outputs.dynamodb_sales, null)
}
