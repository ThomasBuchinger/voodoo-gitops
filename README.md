# Voodoo Board

This repoitory sets up and configures the voodoo board. A SBC running various small services on K3os.

## Installation

K3os is installed via a cloudinit(-ish?) configuration file. [See k3os docs](https://github.com/rancher/k3os/blob/master/README.md#configuration). The full configuration file is generated via a Makefile.

To complete the Setup, boot the k3os-amd64.iso as Live-System (e.g. via PiKVM). Copy the generated `config.yaml` to the system and run `sudo k3os install`

```bash
# Generate cloud-init config in out/config.yaml
make

# Because the config.yaml is too big for the text-paste system of PiKVM, you can host it on a HTTP server
firewall-cmd --add-port 8000/tcp
python -m http.server

# On K3os run (login rancher + ssh-key)
sudo k3os install

http://10.0.0.11:8000/config.yaml
```

## K3os Config

Input files for K3os config.yaml
* `./password.txt` Add the password for the 'rancher'-user here
* `./id_rsa.pub` Add an SSH key to login with the rancher user remotely
* `./sealed.key` and `./sealed.crt` Sealed Secrets private Key
* `k3os/network.config`: Network config
* `k3os/install_flux.sh` Download flus installation files from this repo and copy them into k3s automatic deployment directory /var/lib/rancher/k3s/server/manifests

## Architecture

```mermaid
flowchart TD

k3os-->ci[Cloud-Init]

ci-->os[OS Configuration]
ci--configures-->ss_key{{SealedSecrets PrivateKey}}
ci--copies-->cron[Image Updater Cron Job]
ci--copies-->install_flux[install_flux.sh]

repo_flux_install{{flux-install/}}
install_flux--installs-->FluxCD
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

* The plain secrets are stored in `secrets/<app-dir>/<secret>.yaml`. This path os obviously not pushed to git
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
