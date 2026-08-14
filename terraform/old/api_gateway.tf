# Not needed to the Final Project

# module "api_gateway" {
#   source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//api_gateway?ref=v1"

#   project_name = local.workspace.project_name
#   service_name = local.workspace.service_name
#   environment  = local.workspace.environment

#   body_file = templatefile("${path.module}/assets/openapi.json.tftpl", {
#     environment     = terraform.workspace
#     service_name    = local.workspace.service_name
#     internal_domain = "container-arch.internal.com"
#     domain          = "linuxtips.demo"
#     path            = "calculator"
#     vpclink_id      = data.terraform_remote_state.aws_ecs_cluster.outputs.api_gateway_id
#   })

#   api_key_names = [
#     "Renan Lira"
#   ]
# }
