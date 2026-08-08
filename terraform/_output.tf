output "bastion_id" {
  value = module.bastion.id
}

output "invoke_url" {
  value = module.api_gateway.invoke_url
}
