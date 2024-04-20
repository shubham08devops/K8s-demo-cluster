#!/bin/bash
host_name=$1
sudo hostnamectl set-hostname $host_name
cat <<EOF | sudo tee -a /etc/hosts
$2 k8s-control
$3 k8s-worker1
$4 k8s-worker2
EOF

# On all nodes, set up Docker Engine and containerd. You will need to load some kernel modules and modify some system settings as part of this
process:

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup; params persist across reboots:

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot:

sudo sysctl --system

# Set up the Docker Engine repository:

sudo apt update && sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https

# Add Dockerâ€™s official GPG key:

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository:

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the apt package index:

sudo apt update

# Install Docker Engine, containerd, and Docker Compose:

VERSION_STRING=5:23.0.1-1~ubuntu.20.04~focal
sudo apt install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

# Add your 'cloud_user' to the docker group:

sudo usermod -aG docker $USER

# Log out and log back in so that your group membership is re-evaluated.

# Make sure that 'disabled_plugins' is commented out in your config.toml file:

sudo sed -i 's/disabled_plugins/#disabled_plugins/' /etc/containerd/config.toml

sudo cat /etc/containerd/config.toml

# Restart containerd:

sudo systemctl restart containerd

# On all nodes, disable swap:

sudo swapoff -a

# On all nodes, install kubeadm, kubelet, and kubectl:

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt update && sudo apt install -y kubelet=1.27.0-00 kubeadm=1.27.0-00 kubectl=1.27.0-00

sudo apt-mark hold kubelet kubeadm kubectl
