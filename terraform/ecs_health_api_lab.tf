locals {
  health_api_lab = [
    "bmr",
    "calories",
    "imc",
    "proteins",
    "recommendations",
    "water"
  ]
}

module "ecs_health_api_lab" {
  for_each = toset(local.health_api_lab)
  # source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ecs_service?ref=v1"
  source = "../../container-arch--aws-modules/ecs_service"

  cluster_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.ecs_cluster_name
  project_name   = local.workspace.project_name
  network_values = data.terraform_remote_state.aws_vpc.outputs

  service_name = "nutrition-${each.key}"
  service_port = "30000"
  service_cpu  = 256
  service_mem  = 512

  task_min   = 1
  task_max   = 3
  task_count = 1

  container_image = "fidelissauro/${each.key}-grpc-service:latest"

  enable_lb              = false
  enable_service_connect = true
  service_protocol       = "grpc"
  service_connect_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.service_connect_name
  service_connect_arn    = data.terraform_remote_state.aws_ecs_cluster.outputs.service_connect_arn

  service_healthcheck = {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 10
    interval            = 60
    matcher             = "200-399"
    path                = "/healthz"
    port                = 8080
  }

  service_launch_type = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
    }
  ]

  service_hosts = [
    "${each.key}.container-arch.internal.com"
  ]

  environment_variables = [
    {
      name  = "ZIPKIN_COLLECTOR_ENDPOINT"
      value = "http://jaeger-collector.container-arch.internal.com:80"
    }
  ]

  capabilities = local.workspace.capabilities
}

module "ecs_health_api" {
  # source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ecs_service?ref=v1"
  source = "../../container-arch--aws-modules/ecs_service"

  cluster_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.ecs_cluster_name
  project_name   = local.workspace.project_name
  network_values = data.terraform_remote_state.aws_vpc.outputs

  service_name = "nutrition-health-api"
  service_port = "30000"
  service_cpu  = 256
  service_mem  = 512

  task_min   = 1
  task_max   = 3
  task_count = 1

  container_image = "fidelissauro/health-api:latest"

  enable_service_connect = true
  service_protocol       = "http"
  service_connect_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.cloudmap_name

  enable_lb        = true
  service_listener = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_listener_arn
  alb_arn          = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_arn
  alb_dns_name     = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_dns_name
  alb_zone_id      = data.terraform_remote_state.aws_ecs_cluster.outputs.lb_zone_id

  service_healthcheck = {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 10
    interval            = 60
    matcher             = "200-399"
    path                = "/healthcheck"
    port                = 8080
  }

  service_launch_type = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
    }
  ]

  service_hosts = [
    "health.container-arch.internal.com"
  ]

  environment_variables = [
    {
      name  = "ZIPKIN_COLLECTOR_ENDPOINT"
      value = "http://jaeger-collector.container-arch.discovery.com:80"
    },
    {
      name  = "BMR_SERVICE_ENDPOINT",
      value = "nutrition-bmr.container-arch.discovery.com:30000"
    },
    {
      name  = "IMC_SERVICE_ENDPOINT",
      value = "nutrition-imc.container-arch.discovery.com:30000"
    },
    {
      name  = "RECOMMENDATIONS_SERVICE_ENDPOINT",
      value = "nutrition-recommendations.container-arch.discovery.com:30000"
    },
    {
      name  = "version"
      value = timestamp()
    }
  ]

  capabilities = local.workspace.capabilities
}

module "ecs_jeaeger_collector" {
  # source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//ecs_service?ref=v1"
  source = "../../container-arch--aws-modules/ecs_service"

  cluster_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.ecs_cluster_name
  project_name   = local.workspace.project_name
  network_values = data.terraform_remote_state.aws_vpc.outputs

  service_name = "nutrition-jaeger-collector"
  service_port = "9411"
  service_cpu  = 512
  service_mem  = 1024

  task_min   = 1
  task_max   = 1
  task_count = 1

  container_image = "jaegertracing/all-in-one:1.57"

  enable_lb              = false
  enable_service_connect = true
  service_protocol       = "http"
  service_connect_name   = data.terraform_remote_state.aws_ecs_cluster.outputs.cloudmap_name

  service_healthcheck = {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 10
    interval            = 60
    matcher             = "200-399"
    path                = "/"
    port                = 14269
  }

  service_launch_type = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
    }
  ]

  service_hosts = [
    "jaeger-collector.container-arch.internal.com"
  ]

  environment_variables = [
    {
      name  = "COLLECTOR_ZIPKIN_HOST_PORT"
      value = ":9411"
    }
  ]

  capabilities = local.workspace.capabilities
}
