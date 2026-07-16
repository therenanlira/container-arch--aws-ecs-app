workspaces = {
  dev = {
    allowed_accounts = ["150100906110"]
    environment      = "dev"
    aws_region       = "us-east-2"

    project_name = "container-arch"

    capabilities = ["EC2"]

    service_name        = "chip"
    service_port        = 8080
    service_cpu         = 256
    service_mem         = 512
    service_listener    = 80
    service_launch_type = "EC2"
    service_task_count  = 3

    service_healthcheck = {
      healthy_threshold   = 3
      unhealthy_threshold = 10
      timeout             = 10
      interval            = 60
      matcher             = "200-399"
      path                = "/healthcheck"
      port                = 8080
    }

    service_hosts = [
      "chip.linuxtips.demo"
    ]

    env_vars = [
      {
        name  = "FOO"
        value = "BAR"
      },
      {
        name  = "PING"
        value = "PONG"
      }
    ]
  }
}
