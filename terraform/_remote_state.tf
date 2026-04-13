data "terraform_remote_state" "aws_vpc" {
  backend = "s3"
  config = {
    bucket = "container-arch--terraform-backend"
    key    = "env:/${terraform.workspace}/container-arch/aws-vpc/terraform.tfstate"
    region = local.workspace.aws_region
  }
}

data "terraform_remote_state" "aws_ecs_cluster" {
  backend = "s3"
  config = {
    bucket = "container-arch--terraform-backend"
    key    = "env:/${terraform.workspace}/container-arch/aws-ecs-cluster/terraform.tfstate"
    region = local.workspace.aws_region
  }
}
