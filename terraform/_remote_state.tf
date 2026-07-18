data "terraform_remote_state" "aws_vpc" {
  backend = "s3"
  config = {
    bucket = "150100906110--terraform-backend"
    key    = "env:/${terraform.workspace}/container-arch/aws-vpc/terraform.tfstate"
    region = local.workspace.aws_region
  }
}

data "terraform_remote_state" "aws_ecs_cluster" {
  backend = "s3"
  config = {
    bucket = "150100906110--terraform-backend"
    key    = "env:/${terraform.workspace}/container-arch/aws-ecs-cluster/terraform.tfstate"
    region = local.workspace.aws_region
  }
}
