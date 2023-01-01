#!/bin/bash

function open_firewall() {
  local port=$1
  if ! firewall-cmd --quiet --query-port ${port}; then
    echo "Open Firewall Port: ${port}"
    firewall-cmd --permanent --add-port ${port}
    firewall-cmd --reload
  fi
}

# Some Base OS config
#
dnf install -y vim
dnf install -y cockpit cockpit-navigator cockpit-networkmanager cockpit-packagekit cockpit-pcp cockpit-selinux cockpit-sosreport
systemctl enable --now cockpit.socket
open_firewall 9090/tcp


# Install k3s
#
K3S_CONFIG="/etc/rancher/k3s/config.yaml"
mkdir -p $(dirname $K3S_CONFIG)
echo "selinux: true" > $K3S_CONFIG
curl -sfL https://get.k3s.io | sh -s -
open_firewall 6443/tcp


# Isntall Fluc
#
curl -s https://fluxcd.io/install.sh | sudo bash