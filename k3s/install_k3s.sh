#!/bin/bash


# Some Base OS config
#
dnf install -y vim
dnf install -y cockpit cockpit-navigator cockpit-networkmanager cockpit-packagekit cockpit-pcp cockpit-selinux cockpit-sosreport tar
systemctl enable --now cockpit.socket


# Install k3s
#
systemctl disable --now firewalld
K3S_CONFIG="/etc/rancher/k3s/config.yaml"
mkdir -p $(dirname $K3S_CONFIG)
echo "selinux: true" > $K3S_CONFIG
curl -sfL https://get.k3s.io | sh -s -
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# Isntall Fluc
#
curl -s https://fluxcd.io/install.sh | sudo bash