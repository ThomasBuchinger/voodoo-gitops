data "vault_kv_secret_v2" "api_ca_cert" {
  mount = "cluster"
  name = "cert/apiserver"
}

resource "vault_kv_secret_v2" "kubeconfig" {
  mount = "secret"
  name = "cluster/kubeconfig/${var.name}"
  data_json = jsonencode({
    kubeconfig = data.template_file.kubeconfg_template.rendered
  })
}

data "template_file" "kubeconfg_template" {
  vars = {
    apiserver_ca = "${data.vault_kv_secret_v2.api_ca_cert.data.ca_cert}"
    server = "${var.api_url}"
    name = "${var.name}"
    issuer_url = "${var.oidc_provider_url}"
    client_id = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }
  template = "${file("${path.module}/kubeconfig.tpl")}"
}


variable "name" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}
variable "oidc_provider_url" {
  type = string
}
# variable "api_ca_cert" {
#   type = string
# }
variable "api_url" {
  type = string
}