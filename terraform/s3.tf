module "sales_offload_datalake" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//s3_bucket?ref=v1"

  environment  = local.workspace.environment
  project_name = local.workspace.project_name
  service_name = local.workspace.service_name
}

module "sales_offload_datalake_replication_central" {
  count  = !local.workspace.is_central && local.has_central ? 1 : 0
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//s3_bucket_replication?ref=v1"

  providers = { aws = aws.central }

  environment  = local.workspace.environment
  project_name = local.workspace.project_name
  service_name = local.workspace.service_name

  source_bucket = try(data.terraform_remote_state.central[count.index].outputs.sales_offload_datalake, { bucket = "", region = "" })
  destination_regions = [
    local.workspace.aws_region
  ]

  depends_on = [
    module.sales_offload_datalake
  ]
}

module "sales_offload_datalake_replication_edge" {
  count  = !local.workspace.is_central && local.has_central ? 1 : 0
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//s3_bucket_replication?ref=v1"

  environment  = local.workspace.environment
  project_name = local.workspace.project_name
  service_name = local.workspace.service_name

  source_bucket = {
    bucket = module.sales_offload_datalake.bucket
    region = module.sales_offload_datalake.region
  }

  destination_regions = [
    local.workspace.central_region
  ]

  depends_on = [
    module.sales_offload_datalake
  ]
}
