locals {
  iam_resource_name = "service-task-execution"
}

resource "aws_iam_role" "service_task_execution_role" {
  name = "${var.service_name}--${local.iam_resource_name}--role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Effect = "Allow"
      }
    ]
  })

  tags = {
    Name     = "${var.service_name}--${local.iam_resource_name}--role"
    Resource = "service-task-execution-role"
  }
}

resource "aws_iam_role_policy" "service_execution_policy" {
  name = "${var.service_name}--${local.iam_resource_name}--policy"
  role = aws_iam_role.service_task_execution_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "s3:GetObject",
          "sqs:*",
        ],
        Resource = "*"
      }
    ]
  })
}