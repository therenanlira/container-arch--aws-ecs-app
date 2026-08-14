locals {
  workspace = var.workspaces[terraform.workspace]

  has_central = can(try(data.terraform_remote_state.central[0].outputs, {}))

  tags = {
    Project     = local.workspace.project_name
    Region      = local.workspace.aws_region
    Environment = local.workspace.environment
    Workspace   = terraform.workspace
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}
