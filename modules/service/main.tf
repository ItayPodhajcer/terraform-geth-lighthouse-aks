resource "azurerm_public_ip" "this" {
  name                = "pip-${var.name}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "helm_release" "this" {
  name  = var.name
  chart = var.chart_path

  dynamic "set" {
    for_each = var.values
    iterator = value
    content {
      name  = value.key
      value = value.value
    }
  }

  set {
    name  = var.load_balancer_ip_value
    value = azurerm_public_ip.this.ip_address
  }
}
