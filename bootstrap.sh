#!/bin/bash
set -e

export HOME=/root

IP=$(ip addr show ens4 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
echo $IP > /etc/oldip

hostname kubernetes
hostnamectl set-hostname kubernetes
sed -i 's/localhost$/localhost kubernetes/' /etc/hosts

ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

echo $K8S_VERSION > /etc/k8s_version

export DEBIAN_FRONTEND=noninteractive

echo "waiting 180 seconds for cloud-init to update /etc/apt/sources.list"
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'

apt-get update
apt-get -y install \
    git curl wget \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    conntrack \
    jq vim nano emacs joe \
    inotify-tools \
    socat make golang-go \
    docker.io \
    bash-completion



curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

apt-get -y remove sshguard

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh && ./get_helm.sh && rm ./get_helm.sh

cp -a /tmp/bootstrap/*.sh /usr/bin
cp -a /tmp/bootstrap/*.service /lib/systemd/system/
systemctl daemon-reload

systemctl enable kubeadm kubectl-proxy docker

systemctl start docker

kubeadm config images pull --kubernetes-version $K8S_VERSION

docker pull quay.io/calico/node:v3.3.2
docker pull quay.io/calico/cni:v3.3.2
docker pull quay.io/calico/kube-controllers:v3.3.2
docker pull quay.io/coreos/etcd:v3.3.9
docker pull k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1


# Pre pull workshop images
docker pull nicholasjackson/emojify-website:v0.6.2
docker pull nicholasjackson/emojify-api:v0.8.0
docker pull nicholasjackson/emojify-cache:v0.4.3
docker pull nicholasjackson/emojify-traffic:v0.1.3
docker pull nginx:latest
docker pull machinebox/facebox
docker pull prom/statsd-exporter:latest

docker pull consul:1.4.3
docker pull hashicorp/consul-k8s:0.6.0

docker pull prom/prometheus:v2.6.0
docker pull grafana/grafana:6.0.0-beta3
docker pull prom/statsd-exporter:latest
docker pull k8s.gcr.io/metrics-server-amd64:v0.3.1


MANIFESTS=/etc/kubernetes/manifests

# Download Calico manifests
CALICO_VERSION=3.3
CALICO_MANIFESTS=$MANIFESTS/calico
CALICO_URL=https://docs.projectcalico.org/v$CALICO_VERSION/getting-started/kubernetes/installation/hosted/


mkdir -p $CALICO_MANIFESTS
curl -L -o $CALICO_MANIFESTS/etcd.yaml $CALICO_URL/etcd.yaml
curl -L -o $CALICO_MANIFESTS/calico.yaml $CALICO_URL/calico.yaml
curl -L -o $CALICO_MANIFESTS/rbac.yaml https://docs.projectcalico.org/v$CALICO_VERSION/getting-started/kubernetes/installation/rbac.yaml

cp /tmp/bootstrap/kubernetes-dashboard.yaml $MANIFESTS/dashboard.yaml
# Download dashboard manifest
#curl -L -o $MANIFESTS/dashboard.yaml https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml

