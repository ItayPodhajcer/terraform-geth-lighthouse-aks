provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = module.cluster.host
  client_key             = base64decode(module.cluster.client_key)
  client_certificate     = base64decode(module.cluster.client_certificate)
  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.host
    client_key             = base64decode(module.cluster.client_key)
    client_certificate     = base64decode(module.cluster.client_certificate)
    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
  }
}

locals {
  jwt_secret_name         = "jwt-secret"
  jwt_secret_filename     = "jwt.hex"
  geth_service_name       = "${var.deployment_name}-${random_string.name_suffix.result}-geth"
  lighthouse_service_name = "${var.deployment_name}-${random_string.name_suffix.result}-lighthouse"
}

resource "random_string" "name_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.deployment_name}-${var.location}"
  location = var.location
}

module "cluster" {
  source = "./modules/cluster"

  name                = var.deployment_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  resource_group_id   = azurerm_resource_group.this.id
}

resource "random_password" "jwt_secret" {
  length = 32
}

module "jwt_secret" {
  source = "./modules/secret"

  secret_name     = local.jwt_secret_name
  secret_value    = sha256(random_password.jwt_secret.result)
  secret_filename = local.jwt_secret_filename
}

module "service_geth" {
  source = "./modules/service"

  name                   = local.geth_service_name
  location               = azurerm_resource_group.this.location
  resource_group_name    = azurerm_resource_group.this.name
  chart_path             = "${path.root}/helm/geth"
  load_balancer_ip_value = "externalResources.loadBalancerIP"
  values = {
    "geth.jwtSecretName"                  = local.jwt_secret_name
    "geth.jwtSecretFilename"              = local.jwt_secret_filename
    "externalResources.resourceGroupName" = azurerm_resource_group.this.name
  }
}

module "service_lighthouse" {
  source = "./modules/service"

  name                   = local.lighthouse_service_name
  location               = azurerm_resource_group.this.location
  resource_group_name    = azurerm_resource_group.this.name
  chart_path             = "${path.root}/helm/lighthouse"
  load_balancer_ip_value = "externalResources.loadBalancerIP"
  values = {
    "lighthouse.gethServiceName"          = local.geth_service_name
    "lighthouse.jwtSecretName"            = local.jwt_secret_name
    "lighthouse.jwtSecretFilename"        = local.jwt_secret_filename
    "externalResources.resourceGroupName" = azurerm_resource_group.this.name
  }
}
