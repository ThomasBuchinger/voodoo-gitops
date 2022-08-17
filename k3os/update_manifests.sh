tmp=$(mktemp -d)
cd $tmp
curl -o voodoo-gitops.zip -L https://github.com/ThomasBuchinger/voodoo-gitops/archive/refs/heads/main.zip
unzip voodoo-gitops.zip -d gitops

#mkdir -p /var/lib/rancher/k3s/server/manifests/gitops/
rsync -a --delete gitops /var/lib/rancher/k3s/server/manifests/
