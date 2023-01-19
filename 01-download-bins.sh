#!/bin/bash

source cluster-params.conf

# eval $(grep -i BINARIES_DIR $(pwd)/cluster-params.conf)
rm -f -r $BINARIES_DIR
mkdir -p $BINARIES_DIR

# Downlaod cfssl and cfssljson.
wget -q --show-progress --https-only --timestamping \
    https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl \
    https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson
mv cfssl cfssljson $BINARIES_DIR


# Download the official etcd release binaries from the etcd GitHub project.
wget -q --show-progress --https-only --timestamping \
    "https://github.com/etcd-io/etcd/releases/download/v${ETCD_VER}/etcd-v${ETCD_VER}-linux-amd64.tar.gz"
mv "etcd-v${ETCD_VER}-linux-amd64.tar.gz" $BINARIES_DIR

# Download the Kubernetes Controller Binaries
wget -q --show-progress --https-only --timestamping \
    "https://storage.googleapis.com/kubernetes-release/release/v${APISRV_VER}/bin/linux/amd64/kube-apiserver" \
    "https://storage.googleapis.com/kubernetes-release/release/v${CTRL_MNG_VER}/bin/linux/amd64/kube-controller-manager" \
    "https://storage.googleapis.com/kubernetes-release/release/v${SCHDLR_VER}/bin/linux/amd64/kube-scheduler" \
    "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VER}/bin/linux/amd64/kubectl"
mv kube-apiserver kube-controller-manager kube-scheduler kubectl $BINARIES_DIR

# Download nginx package and it's dependencies.
sudo apt-get clean
for i in $(apt-cache depends nginx  | grep -E 'Depends|Recommends|Suggests' | cut -d ':' -f 2,3 | sed -e s/'<'/''/ -e s/'>'/''/);
    do sudo yes | sudo apt install --download-only --reinstall $i
done
sudo yes | sudo apt install --download-only --reinstall nginx
sudo yes | sudo apt install --download-only --reinstall gdebi-core

cd $BINARIES_DIR
mkdir nginx
sudo cp -R /var/cache/apt/archives/*.deb ./nginx/


# Kubernetes worker-node bootstrap downloads.
wget -q --show-progress --https-only --timestamping \
  "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRI_VER}/crictl-v${CRI_VER}-linux-amd64.tar.gz" \
  "https://github.com/opencontainers/runc/releases/download/v${OPNCONT_VER}/runc.amd64" \
  "https://github.com/containernetworking/plugins/releases/download/v${CNIPLG_VER}/cni-plugins-linux-amd64-v${CNIPLG_VER}.tgz" \
  "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VER}/containerd-${CONTAINERD_VER}-linux-amd64.tar.gz" \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBEPROX_VER}/bin/linux/amd64/kube-proxy" \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBELET_VER}/bin/linux/amd64/kubelet"


mkdir worker-bins
mv "crictl-v${CRI_VER}-linux-amd64.tar.gz" runc.amd64 "cni-plugins-linux-amd64-v${CNIPLG_VER}.tgz" \
   "containerd-${CONTAINERD_VER}-linux-amd64.tar.gz" kube-proxy kubelet worker-bins

# Download socat conntrack ipset packages with dependencies.   
sudo apt-get clean
for i in $(apt-cache depends socat conntrack ipset | grep -E 'Depends|Recommends|Suggests' | cut -d ':' -f 2,3 | sed -e s/'<'/''/ -e s/'>'/''/);
    do sudo yes | sudo apt install --download-only --reinstall $i
done

sudo yes | sudo apt install --download-only --reinstall socat conntrack ipset
sudo cp -R /var/cache/apt/archives/*.deb ./worker-bins

# Download .yaml manifest file for coredns deployment.
wget -q --show-progress --https-only --timestamping "https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml"