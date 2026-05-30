#!/bin/bash
MANIFEST_DIR=/var/lib/rancher/k3s/server/manifests/
BRANCH=${1:-main}

curl -s https://fluxcd.io/install.sh | sudo bash
curl -L -o $MANIFEST_DIR/flux-operator.yaml https://raw.githubusercontent.com/ThomasBuchinger/voodoo-gitops/$BRANCH/flux-install/flux-operator.yaml
curl -L -o $MANIFEST_DIR/voodoo-gitops.yaml https://raw.githubusercontent.com/ThomasBuchinger/voodoo-gitops/$BRANCH/flux-install/voodoo-gitops.yaml
sed -i -e "s|refs/heads/main|refs/heads/$BRANCH|"  $MANIFEST_DIR/voodoo-gitops.yaml
