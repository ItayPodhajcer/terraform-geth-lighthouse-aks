output "geth_fqdn" {
  value = "${local.geth_service_name}.${var.location}.cloudapp.azure.com"
}

output "lighthouse_fqdn" {
  value = "${local.lighthouse_service_name}.${var.location}.cloudapp.azure.com"
}
