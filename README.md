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

# On K3os run
sudo k3os install

http://10.0.0.11:8000/config.yaml
```

## Input files

* `password.txt` Add the password for the 'rancher'-user here
* `id_rsa.pub` Add an SSH key to login with the rancher user remotely
* ``sealed.key`/`sealed.crt` Sealed Secrets private Key

## Other files

* `k3os/network.config`: Network config
* `k3os/update_manifests.sh` Download this repo and copy the content is gitops/ into k3s automatic deployment directory /var/lib/rancher/k3s/server/manifests
* `secrets/` contains the plain text Kubernetes Secrets before sealing them with kubeseal

## Kubeseal

```bash
kubeseal --cert sealed.crt 
```

