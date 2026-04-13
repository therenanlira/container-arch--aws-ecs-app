locals {
  efs_resource_name = "${var.cluster_name}--${var.service_name}"
}

resource "aws_efs_file_system" "efs" {
  creation_token   = "${local.efs_resource_name}--efs"
  performance_mode = "generalPurpose"
}

resource "aws_security_group" "efs_security_group" {
  name   = "${local.efs_resource_name}--efs-sg"
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  count = length(local.private_subnets)

  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = local.private_subnets[count.index]
  security_groups = [
    aws_security_group.efs_security_group.id
  ]
}