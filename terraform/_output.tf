# output "bastion_id" {
#   value = module.bastion.id
# }

# output "invoke_url" {
#   value = module.api_gateway.invoke_url
# }

output "dynamodb_idempotency" {
  value = local.workspace.is_central ? module.dynamodb_idempotency[0].arn : null
}

output "dynamodb_sales" {
  value = local.workspace.is_central ? module.dynamodb_sales[0].arn : null
}

output "sales_offload_datalake" {
  value = {
    bucket = module.sales_offload_datalake.bucket
    region = module.sales_offload_datalake.region
  }
}
output "sqs_sales_arn" {
  value = module.sqs_sales.arn
}

output "sns_sales_arn" {
  value = module.sns_sales.arn
}

output "sns_sales_suffix" {
  value = module.sns_sales.topic_suffix
}
