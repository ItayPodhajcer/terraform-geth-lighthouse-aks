resource "kubernetes_secret" "this" {
  metadata {
    name = var.secret_name
  }

  data = {
    "${var.secret_filename}" = var.secret_value
  }

  type = "Opaque"
}
