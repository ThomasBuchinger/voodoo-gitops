RRANCH=${1:-main}
tmp=$(mktemp -d)


cd $tmp
curl -o voodoo-gitops.zip -L https://github.com/ThomasBuchinger/voodoo-gitops/archive/refs/heads/${BRANCH}.zip
unzip voodoo-gitops.zip

mkdir -p /var/lib/rancher/k3s/server/manifests/gitops/
rsync -a --delete gitops/voodoo-gitops-${BRANCH}/gitops /var/lib/rancher/k3s/server/manifests/
