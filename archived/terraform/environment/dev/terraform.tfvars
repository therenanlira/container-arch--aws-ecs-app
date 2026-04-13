#### GENERAL CONFIGURATION ####

region = "us-east-1"

#### SSM VPC PARAMETERS ####

ssm_vpc_id           = "linuxtips-vpc-vpc-id"
ssm_private_subnet_1 = "linuxtips-vpc-private-subnet-1a"
ssm_private_subnet_2 = "linuxtips-vpc-private-subnet-1b"
ssm_private_subnet_3 = "linuxtips-vpc-private-subnet-1c"
ssm_listener_arn     = "linuxtips-ecscluster--load-balancer-http-listener-arn"
ssm_alb_arn          = "linuxtips-ecscluster--load-balancer-arn"

#### ECS TASK DEFINITION ####

cluster_name       = "linuxtips-ecscluster"
service_name       = "linuxtips-app"
service_port       = 8080
service_cpu        = 256
service_memory     = 512
service_task_count = 2
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

environment_variables = [
  {
    name  = "foo"
    value = "bar"
  },
  {
    name  = "ping"
    value = "pong"
  }
]

capabilities = [
  "EC2",
  "FARGATE"
]

service_healthcheck = {
  "healthy_threshold"   = 3
  "unhealthy_threshold" = 10
  "timeout"             = 10
  "interval"            = 60
  "matcher"             = "200-399"
  "path"                = "/healthcheck"
  "port"                = "8080"
}

service_hosts = [
  "app.linuxtips.demo"
]

#### ECS AUTO SCALING ####

scale_type   = "requests_tracking"
task_minimum = 1
task_maximum = 5

scale_out_cpu_threshold       = 50
scale_out_adjustment          = 1
scale_out_comparison_operator = "GreaterThanOrEqualToThreshold"
scale_out_statistic           = "Average"
scale_out_period              = 30
scale_out_evaluation_periods  = 2
scale_out_cooldown            = 30

scale_in_cpu_threshold       = 30
scale_in_adjustment          = -1
scale_in_comparison_operator = "LessThanOrEqualToThreshold"
scale_in_statistic           = "Average"
scale_in_period              = 60
scale_in_evaluation_periods  = 2
scale_in_cooldown            = 60

scale_cpu_tracking      = 50
scale_requests_tracking = 30