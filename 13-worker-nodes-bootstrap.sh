#!/bin/bash

source cluster-params.conf

function worker_bootstrap(){
    local CRI_VER=$1
    local CONTAINERD_VER=$2
    local CNIPLG_VER=$3
    local POD_CIDR=$4

    #sudo apt-get update
    
    pushd worker-bins
    sudo dpkg -i gdebi-core*.deb
    sudo yes | sudo gdebi socat*
    sudo yes | sudo gdebi conntrack*
    sudo yes | sudo gdebi ipset*

    sudo swapoff -a    

    sudo mkdir -p \
      /etc/cni/net.d \
      /opt/cni/bin \
      /var/lib/kubelet \
      /var/lib/kube-proxy \
      /var/lib/kubernetes \
      /var/run/kubernetes
      
    sudo mkdir containerd
    
    tar -xvf "crictl-v${CRI_VER}-linux-amd64.tar.gz"
    sudo tar -xvf "containerd-${CONTAINERD_VER}-linux-amd64.tar.gz" -C containerd
    sudo tar -xvf "cni-plugins-linux-amd64-v${CNIPLG_VER}.tgz" -C /opt/cni/bin/
    sudo mv runc.amd64 runc
    chmod +x crictl kubectl kube-proxy kubelet runc 
    sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
    sudo mv containerd/bin/* /bin/

    popd

    cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.4.0",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

    cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.4.0",
    "name": "lo",
    "type": "loopback"
}
EOF


    # Create the containerd configuration file.
    sudo mkdir -p /etc/containerd/

cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF

    # Create the containerd.service systemd unit file.
    cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF


    {
        sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
        sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
        sudo mv ca.pem /var/lib/kubernetes/
    }

    # Create the kubelet-config.yaml configuration file.
    cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF
    # The resolvConf configuration is used to avoid loops when using 
    # CoreDNS for service discovery on systems running systemd-resolved

    # Create the kubelet.service systemd unit file.
    cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    # Configure the Kubernetes Proxy
    sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

    # Create the kube-proxy-config.yaml configuration file:
    cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF

    # Create the kube-proxy.service systemd unit file:
    cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    # Start the Worker Services
    {
        sudo systemctl daemon-reload
        sudo systemctl enable containerd kubelet kube-proxy
        sudo systemctl start containerd kubelet kube-proxy
    }
}


for i in "${!WORKERS[@]}" ; do
    ssh "${USER}"@"${WORKERS_EXT_IPS[$i]}" "mkdir worker-bins"

    cd $BINARIES_DIR
    pushd nginx
    scp gdebi-core_*.deb ${USER}@"${WORKERS_EXT_IPS[$i]}":~/worker-bins
    popd
    cp kubectl worker-bins   #

    pushd worker-bins
    for file in * ; do
        scp "$file" ${USER}@"${WORKERS_EXT_IPS[$i]}":~/worker-bins
    done

    ssh "${USER}"@"${WORKERS_EXT_IPS[$i]}" << EOF
$(typeset -f worker_bootstrap ${CRI_VER} ${CONTAINERD_VER} ${CNIPLG_VER} ${POD_CIDR[$i]})
worker_bootstrap ${CRI_VER} ${CONTAINERD_VER} ${CNIPLG_VER} ${POD_CIDR[$i]}
EOF
popd
done
# List the registered Kubernetes nodes: kubectl get nodes --kubeconfig admin.kubeconfig