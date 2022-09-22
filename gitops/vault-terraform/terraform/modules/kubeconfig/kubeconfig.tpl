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
