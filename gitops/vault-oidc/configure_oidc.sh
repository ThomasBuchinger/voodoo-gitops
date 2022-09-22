#!/bin/bash

#ISSUER=$(kubectl get secret -n default oidc-kubelogin --template '{{.data.oidc_provider_url}}' | base64 -d)

if [ ${ISSUER:-x} = "x" ]; then
  echo "No ISSUER configured...."
  exit 1
fi

if [ ${CLIENT_ID:-x} = "x" ]; then
  echo "No CLIENT_ID configured"
  exit 1
fi

if [ ${CLIENT_SECRET:-x} = "x" ]; then
  echo "SNo CLIENT_SECRET configured"
  exit 0
fi

# === Update /etc/hosts ===
HOST=$(echo $ISSUER | awk -F/ '{print $3}')
if ! grep -q "$HOST" /host-etc/hosts; then
  echo "DRY-RUN: Adding $HOST to /etc/host"
  # echo "127.0.0.1 $HOST" >> /host-etc/hosts
fi

EXISTING_ISSUER=$(grep -o -e "oidc-issuer-url=[^ ']*" /etc/init.d/k3s-service)
EXISTING_CLIENT_ID=$(grep -o -e "oidc-client-id=[^ ']*" /etc/init.d/k3s-service)

if [[ ${EXISTING_ISSUER:-x} = "oidc-issuer-url=${ISSUER:-y}" && ${EXISTING_CLIENT_ID:-x} = "oidc-client-id=${CLIENT_ID:-y}" ]]; then
  echo "Existing config matched required Config. Nothing to do"
  exit 0
fi

echo "Updating OIDC config... Issuer=$ISSUER ClientID=$CLIENT_ID"
cat >/config/oidc_config.yaml <<EOF
k3os:
  k3s_args:
  - --kube-apiserver-arg=oidc-client-id=$CLIENT_ID
  - --kube-apiserver-arg=oidc-issuer-url=$ISSUER
  - --kube-apiserver-arg=oidc-username-claim=username
  - --kube-apiserver-arg=oidc-groups-claim=groups
  - --kube-apiserver-arg=oidc-groups-prefix=
  - --kube-apiserver-arg=oidc-username-prefix=

EOF
#service k3s-service restart