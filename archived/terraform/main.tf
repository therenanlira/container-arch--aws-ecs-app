module "service" {
  source = "git@github.com:therenanlira/container-arch--aws-ecs--module.git?ref=v1.3.0"
  region = var.region

  container_image = var.container_image

  cluster_name         = var.cluster_name
  service_name         = var.service_name
  service_port         = var.service_port
  service_cpu          = var.service_cpu
  service_memory       = var.service_memory
  service_listener_arn = data.aws_ssm_parameter.listener_arn.value
  service_healthcheck  = var.service_healthcheck
  service_launch_type  = var.service_launch_type
  service_task_count   = var.service_task_count
  service_hosts        = var.service_hosts

  service_task_execution_role_arn = aws_iam_role.service_task_execution_role.arn

  vpc_id = data.aws_ssm_parameter.vpc_id.value

  private_subnets = local.private_subnets

  environment_variables = var.environment_variables
  capabilities          = var.capabilities

  secrets = [
    {
      name      = "SSM_PARAMETER_VALUE_VARIABLE"
      valueFrom = aws_ssm_parameter.parameter.arn
    },
    {
      name      = "SECRET_MANAGER_VALUE_VARIABLE"
      valueFrom = aws_secretsmanager_secret.secret.arn
    }
  ]

  scale_type   = var.scale_type
  task_minimum = var.task_minimum
  task_maximum = var.task_maximum

  scale_out_cpu_threshold       = var.scale_out_cpu_threshold
  scale_out_adjustment          = var.scale_out_adjustment
  scale_out_comparison_operator = var.scale_out_comparison_operator
  scale_out_statistic           = var.scale_out_statistic
  scale_out_period              = var.scale_out_period
  scale_out_evaluation_periods  = var.scale_out_evaluation_periods
  scale_out_cooldown            = var.scale_out_cooldown

  scale_in_cpu_threshold       = var.scale_in_cpu_threshold
  scale_in_adjustment          = var.scale_in_adjustment
  scale_in_comparison_operator = var.scale_in_comparison_operator
  scale_in_statistic           = var.scale_in_statistic
  scale_in_period              = var.scale_in_period
  scale_in_evaluation_periods  = var.scale_in_evaluation_periods
  scale_in_cooldown            = var.scale_in_cooldown

  scale_cpu_tracking      = var.scale_cpu_tracking
  scale_requests_tracking = var.scale_requests_tracking
  alb_arn                 = data.aws_ssm_parameter.alb_arn.value

  efs_volumes = [
    {
      volume_name      = "example-volume"
      file_system_id   = aws_efs_file_system.efs.id
      file_system_root = "/"
      mount_point      = "/mnt/efs"
      read_only        = false
    }
  ]
}
