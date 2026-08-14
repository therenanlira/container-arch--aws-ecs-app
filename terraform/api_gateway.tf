module "api_gateway_sales" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//api_gateway?ref=v1"

  project_name = local.workspace.project_name
  service_name = "sales-api"
  environment  = local.workspace.environment

  body_file = templatefile("${path.module}/assets/openapi-sales.json.tftpl", {
    environment  = local.workspace.environment
    alb_dns_name = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_dns_name
    service_host = "sales.container-arch.internal.com"
  })

  api_key_names = [
    "${local.workspace.environment}-${local.workspace.aws_region}-sales-api"
  ]
}
