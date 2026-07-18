workspaces = {
  dev = {
    allowed_accounts = ["150100906110"]
    environment      = "dev"
    aws_region       = "us-east-2"

    project_name = "container-arch"

    capabilities = ["EC2"]

    service_name       = "app"
    service_port       = 8080
    service_cpu        = 256
    service_mem        = 512
    service_listener   = 80
    service_task_count = 1

    service_launch_type = [
      {
        capacity_provider = "FARGATE"
        weight            = 50
      },
      {
        capacity_provider = "FARGATE_SPOT"
        weight            = 50
      }
    ]

    scale_type              = "requests-tracking"
    scale_tracking_cpu      = 50
    scale_tracking_requests = 30
    task_min                = 2
    task_max                = 4

    scale_out_cpu = {
      threshold           = 50
      adjustment          = 2
      comparison_operator = "GreaterThanOrEqualToThreshold"
      statistic           = "Average"
      period              = 60
      evaluation_periods  = 2
      cooldown            = 60
    }

    scale_in_cpu = {
      threshold           = 30
      adjustment          = -1
      comparison_operator = "LessThanOrEqualToThreshold"
      statistic           = "Average"
      period              = 60
      evaluation_periods  = 2
      cooldown            = 60
    }


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
      "app.linuxtips.demo"
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
