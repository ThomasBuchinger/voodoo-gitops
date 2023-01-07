# Cluster: evergreen

This repoitory managed the evergreen-cluster, a single-node Kubernetes cluster providing infrastructure services to the rest of the Network.

## Installation

First Install RockyLinux 8 and setup passwordless SSH access to the server.

```bash
# Generate the SealedSecret encryption secret
make

# Install and configure node
#
# ssh-install: installs k3s and a few OS packages
# ssh-kubeconfig: fetch the admin kubeconfig
# ssh-configure: bootstrap flux
make install
```

### Switch branches
To switch to a different branch, log into the server and run `~/bin/install_flux.sh <BRANCH>`

## Architecture
All applcations are handled by fluxcd
linux--installs-->fluxchart

```mermaid
flowchart TB

subgraph os[RockyLinux 8]
direction TB
Makefile-->os_conf[Configure OS]
Makefile-->k3s[Install k3s]
Makefile-->copy_ss[Copy SealedSecret]
Makefile-->bootstrap[Bootstrap Flux]

end

os--deploys-->flux

subgraph flux[FluxCD]
direction TB

repo_flux_install{{Repo: flux-install/}}-->FluxCD
repo_flux{{repo: gitops/flux/}}-->FluxCD

FluxCD-->pihole
FluxCD-->eso[External Secrets]
FluxCD-->cert[Cert Manager]
FluxCD-->node-exporter
FluxCD-->console[OKD Console]
FluxCD-->shell-ddns
FluxCD-->wastebin
FluxCD-->tfc[Flux Terraform Controller]
FluxCD-->ss[SealedSecrets]
FluxCD-->vaultop[Vault Operator]
end
```

## Secrets Management
Secrets are handled via a combination of vault and SealedSecrets.

* The plain secrets are stored in `secrets/<app-dir>/<secret>.yaml`. This path os obviously not pushed to git
* The Makefile encrypts the secrets using `kubeseal` and stores them in `gitops/<app-dir>/<secret>-sealed.yaml`
* Banzaicloud Vault Operator stores the decrypted Secrets in Vault
* The External-Secrets-Operator fetches the Secrets from vault and creates the actual Secret

```bash
# Rotate encryption key
mv sealed.crt sealed.crt.old
openssl req -new -x509 -nodes -days 30 -key sealed.key -out sealed.crt -subj "/CN=sealed-secret/O=sealed-secret"

# to update Secrets run
make kubeseal
```
### Secret Flow

```mermaid
flowchart TD
ss{{Sealed Secrets in Repo}}

ss_creds-->Pihole
ss-->ss_creds[Static Credentials]
ss-->ss_github[GitHub]
ss-->ss_cf[Cloudflare]
ss-->ss_approle[Approle SecretIDs]

tfc{{Vault Terraform Config}}
tfc--uses-->vault-static
tfc--configures-->vault-auth

ss_creds--Admin Password-->vault
ss_creds-->vault-static
ss_github-->vault-static
ss_cf-->vault-static
ss_approle-->vault-static

certman_cert[CertManaager Certificates]
tf_oidc[Terraform OIDC Config]
certman_cert-->vault-cluster
tf_oidc-->vault-cluster


es[External Secrets Operator]
vault-static--->es
vault-cluster--->es


subgraph vault[Hashicorp Vault]

vault-static{{Vault Static Secrets Engine}}
vault-auth{{Auth Config}}
vault-cluster{{Vault Cluster Secrets Engine}}

vault-cluster-->oidc-config[OIDC Configs]
vault-cluster-->external-certs[Managed Certificate]
vault-cluster-->kubeconfig[Kubeconfig for local Cluster]

end


es--cf_apikey_dnsedit-_key-->CertManager
es--cf_tunnel_token-_key-->cloudflared
es--cf_apikey_dnsedit-_key-->ShellDDNS
es--OIDC-Config-->vault-oidc[Cluster OIDC Login]

```




