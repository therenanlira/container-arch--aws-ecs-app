workspaces = {
  dev = {
    allowed_accounts = ["923672208632"]
    environment      = "dev"
    aws_region       = "us-east-1"

    project_name = "container-arch"

    service_name     = "chip"
    service_port     = 8080
    service_cpu      = 256
    service_mem      = 512
    service_listener = 80
  }
}
