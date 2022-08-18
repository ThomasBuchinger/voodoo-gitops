BRANCH=${1:-main}
tmp=$(mktemp -d)


echo "Download Archive..."
cd $tmp
status_code=$(curl --write-out '%{http_code}' -O -L https://github.com/ThomasBuchinger/voodoo-gitops/archive/refs/heads/${BRANCH}.zip)
if [ "200" != "$status_code" ]; then
  echo "Unable to download ZIP for '${BRANCH}'. HTTP Status: ${status_code}"
  exit 1
fi

unzip "${BRANCH}.zip" > /dev/null

echo "Copying Manifests..."
mkdir -p /var/lib/rancher/k3s/server/manifests/gitops/
rsync -avh --delete "voodoo-gitops-${BRANCH}/gitops" "/var/lib/rancher/k3s/server/manifests/"
