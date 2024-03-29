#!/bin/bash


# Some Base OS config
#
dnf install -y vim
dnf install -y cockpit cockpit-networkmanager cockpit-packagekit cockpit-pcp cockpit-selinux cockpit-sosreport tar
systemctl enable --now cockpit.socket
systemctl enable --now pmlogger.service

# Automatic Updates
#
dnf install -y dnf-automatic
sed -i -e 's/apply_updates.*=.*no/apply_updates = yes/g' -e '/apply_updates/a reboot = when-needed' /etc/dnf/automatic.conf
systemctl enable --now dnf-automatic.timer



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