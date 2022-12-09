# Voodoo Board

This repoitory sets up and configures the voodoo board. A SBC running various small services on Talos.

## Installation

To install Talos, you first need to boot the `talos-amd64.iso` on your node. Then you apply the talos configuration to the node.

```bash
# Generate a OpenSSL keypair for sealed-secrets
# openssl ...

# Set NODE_IP and DHCP_IP in the Makefile
make talos-config

# Now boot the Node into the talos.iso
make talos-apply

# Wait for the initial Bootstrap to be complete
make talos bootstrap

```


## Architecture

```mermaid
flowchart TD

talos-->conf[Talos Config]

conf-->os[OS Configuration]
conf--configures-->ss_key{{SealedSecrets PrivateKey}}
conf--installs-->FluxCD

repo_flux_install{{flux-install/}}
repo_flux_install-->FluxCD

repo_flux{{gitops/flux/}}-->FluxCD
FluxCD-->pihole
FluxCD-->cloudflared
FluxCD-->eso[External Secrets]
FluxCD-->node-exporter
FluxCD-->console[OKD Console]
FluxCD-->shell-ddns
FluxCD-->static
FluxCD-->wastebin
FluxCD-->tfc[Flux Terraform Controller]
FluxCD-->ss[SealedSecrets]

FluxCD---->vaultop[Vault Operator]
vaultop--deploys-->Vault
ss----vaultcfg
tfc-->vaultcfg{{Vault Config}}
vaultcfg--terraforms-->Vault

```
All applcations are handled by fluxcd

### Secrets Management
Secrets are handled via a combination of vault and SealedSecrets.

* The plain secrets are stored in `secrets/<app-dir>/<secret>.yaml`. This path is obviously not checked in.
* The Makefile encrypts the secrets using `kubeseal` and stores them in `gitops/<app-dir>/<secret>-sealed.yaml`
* Banzaicloud Vault Operator stores the decrypted Secrets in Vault
* The External-Secrets-Otperator fetches the Secrets from vault and creates the actual Secret

```bash
# Rotate encryption key
openssl req -new -x509 -nodes -days 30 -key sealed.key -out sealed2.crt -subj "/CN=sealed-secret/O=sealed-secret"

# to update Secrets run
make kubeseal
```
#### Secret Flow

```mermaid

flowchart TD

repo{{Sealed Secrets in Repo}}
repo-->Cloudflare
repo-->GitHub
repo-->secretids[Approle SecretIDs]
repo-->creds[Static Credentials]

vault-static{{Vault Static Secrets Engine}}
GitHub-->vault-static
Cloudflare-->vault-static
secretids-->vault-static
creds-->vault-static

vault-cluster{{Vault Cluster Secrets Engine}}
certs[CertManager Certificates]--->vault-cluster
vault-cluster-->oidc-config[OIDC Configs]
vault-cluster-->external-certs[Managed Certificate]
vault-cluster-->kubeconfig[Kubeconfig for local Cluster]
vault-cluster-->es

es{{External Secrets Maager}}
vault-static--> es
es--cf_apikey_dnsedit-_key-->CertManager
es--cf_tunnel_token-_key-->cloudflared
es--cf_apikey_dnsedit-_key-->ShellDDNS
es--OIDC-Config-->vault-oidc[Cluster OIDC Login]


vault-auth{{Vault Auth Config}}
vault-tf-approle-->vault-auth
creds-->vault-auth
creds-->PiHole

vault-tf-approle{{Vault Terraform Approle Config}}
vault-static--secret-ids-->vault-tf-approle

vault-tf-oidc{{Vault Terraform OIDC Client}}
vault-tf-oidc--->vault-cluster

```
