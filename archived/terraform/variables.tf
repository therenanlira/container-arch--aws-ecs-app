#### GENERAL CONFIGURATION ####

variable "region" {
  description = "The region where the resources will be created"
  type        = string
}

#### ECS APP CONFIGURATION ####

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "container_image" {
  type        = string
  description = "The container image to run"
  default     = "nginx:latest"
}

variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "service_port" {
  description = "The port on which the service listens"
  type        = number
}

variable "service_cpu" {
  description = "The number of CPU units to reserve for the service"
  type        = number
}

variable "service_memory" {
  description = "The amount of memory to reserve for the service"
  type        = number
}

variable "service_healthcheck" {
  description = "The healthcheck for the service"
  type        = map(string)
}

variable "service_launch_type" {
  description = "The launch type for the service"
  type = list(object({
    capacity_provider = string
    weight            = number
  }))
  default = [
    {
      capacity_provider = "SPOT"
      weight            = 100
    }
  ]
}

variable "service_task_count" {
  description = "The number of tasks to run"
  type        = number
}

variable "service_hosts" {
  description = "The hosts for the service"
  type        = list(string)
}

#### ECS TASK DEFINITION ####

variable "environment_variables" {
  description = "The environment variables for the task definition"
  type = list(object({
    name  = string
    value = string
  }))
}

variable "secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "Secret Manager or Parameter Store list of secrets"
  default     = []
}

variable "capabilities" {
  description = "The capabilities for the task definition"
  type        = list(string)
}

#### SSM VPC PARAMETERS ####

variable "ssm_vpc_id" {
  description = "The SSM parameter name for the VPC ID"
  type        = string
}

variable "ssm_private_subnet_1" {
  description = "The SSM parameter name for the private subnet 1"
  type        = string
}

variable "ssm_private_subnet_2" {
  description = "The SSM parameter name for the private subnet 2"
  type        = string
}

variable "ssm_private_subnet_3" {
  description = "The SSM parameter name for the private subnet 3"
  type        = string
}

variable "ssm_listener_arn" {
  description = "The listener rule for the service"
  type        = string
}

variable "ssm_alb_arn" {
  description = "The ARN of the ALB"
  type        = string
}

#### ECS AUTO SCALING ####

variable "scale_type" {
  description = "The scale type for the task definition"
  type        = string
}

variable "task_minimum" {
  description = "The minimum number of tasks to run"
  type        = number
}

variable "task_maximum" {
  description = "The maximum number of tasks to run"
  type        = number
}

variable "scale_out_cpu_threshold" {
  description = "The CPU threshold for scaling out"
  type        = number
}

variable "scale_out_adjustment" {
  description = "The number of tasks to add when scaling out"
  type        = number
}

variable "scale_out_comparison_operator" {
  description = "The comparison operator for scaling out"
  type        = string
}

variable "scale_out_statistic" {
  description = "The statistic for scaling out"
  type        = string
}

variable "scale_out_period" {
  description = "The period for scaling out"
  type        = number
}

variable "scale_out_evaluation_periods" {
  description = "The evaluation periods for scaling out"
  type        = number
}

variable "scale_out_cooldown" {
  description = "The cooldown for scaling out"
  type        = number
}

variable "scale_in_cpu_threshold" {
  description = "The CPU threshold for scaling in"
  type        = number
}

variable "scale_in_adjustment" {
  description = "The number of tasks to add when scaling in"
  type        = number
}

variable "scale_in_comparison_operator" {
  description = "The comparison operator for scaling in"
  type        = string
}

variable "scale_in_statistic" {
  description = "The statistic for scaling in"
  type        = string
}

variable "scale_in_period" {
  description = "The period for scaling in"
  type        = number
}

variable "scale_in_evaluation_periods" {
  description = "The evaluation periods for scaling in"
  type        = number
}

variable "scale_in_cooldown" {
  description = "The cooldown for scaling in"
  type        = number
}

variable "scale_cpu_tracking" {
  description = "The name of the CPU tracking resource"
  type        = number
}

variable "scale_requests_tracking" {
  description = "The name of the requests tracking resource"
  type        = number
}

variable "efs_volumes" {
  description = "The EFS volumes for the task definition"
  type = list(object({
    volume_name      = string
    file_system_id   = string
    file_system_root = string
    mount_point      = string
    read_only        = bool
  }))
  default = []
}