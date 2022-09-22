data "vault_kv_secret_v2" "api_ca_cert" {
  mount = "cluster"
  name = "cert/apiserver"
}

resource "vault_kv_secret_v2" "kubeconfig" {
  mount = "secret"
  name = "cluster/kubeconfig/${var.name}"
  data_json = jsonencode({
    foo = "bar"
  })
}

data "template_file" "kubeconfg_template" {
  vars = {
    apiserver_ca = data.vault_kv_secret_v2.api_ca_cert.data.ca_cert
    server = var.api_url
    name = var.name
    issuer_url = var.oidc_provider_url
    client_id = var.client_id
    client_secret = var.client_secret
  }
  template = <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${apiserver_ca}
    server: ${server}
  name: ${name}
contexts:
- context:
    cluster: ${name}
    user: oidc
  name: ${name}
current-context: ${name}
kind: Config
preferences: {}
users:
- name: oidc
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - oidc-login
      - get-token
      - --oidc-issuer-url=${issuer_url}
      - --oidc-client-id=${client_id}
      - --oidc-client-secret=${client_secret}
      - --oidc-extra-scope=username
      - --oidc-extra-scope=groups
      command: kubectl
      env: null
      interactiveMode: IfAvailable
      provideClusterInfo: false
EOF
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