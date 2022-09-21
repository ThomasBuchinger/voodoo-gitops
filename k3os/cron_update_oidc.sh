#!/bin/bash

ISSUER=$(kubectl get secret -n default oidc-kubelogin --template '{{.data.oidc_provider_url}}' | base64 -d)

if [ ${ISSUER:-x} = "x" ]; then
  echo "Secret does not (yet?) exist. Nothing to do"
  exit 0
fi

# === Update /etc/hosts ===
HOST=$(echo $ISSUER | awk -F/ '{print $3}')
if ! grep -q "$HOST" /etc/hosts; then
  echo "Adding $HOST to /etc/host"
  echo "127.0.0.1 $HOST" >> /etc/hosts
fi


# === Update K3s Config ===
CLIENT_ID=$(kubectl get secret -n default oidc-kubelogin --template '{{.data.client_id}}' | base64 -d)

EXISTING_ISSUER=$(grep -o -e "oidc-issuer-url=[^ ']*" /etc/init.d/k3s-service)
EXISTING_CLIENT_ID=$(grep -o -e "oidc-client-id=[^ ']*" /etc/init.d/k3s-service)

if [[ ${EXISTING_ISSUER:-x} = "oidc-issuer-url=${ISSUER:-y}" && ${EXISTING_CLIENT_ID:-x} = "oidc-client-id=${CLIENT_ID:-y}" ]]; then
  echo "Existing config matched required Config. Nothing to do"
  exit 0
fi

echo "Updating OIDC config... Issuer=$ISSUER ClientID=$CLIENT_ID"
sed -i -e "s|oidc-issuer-url=[^ ']*|oidc-issuer-url=$ISSUER|g" -e "s|oidc-client-id=[^ ']*|oidc-client-id=$CLIENT_ID|g" /etc/init.d/k3s-service
service k3s-service restart
