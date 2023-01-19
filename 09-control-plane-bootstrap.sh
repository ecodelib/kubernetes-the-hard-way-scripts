#!/bin/bash

source cluster-params.conf


function control_bootstrap(){
    local INTERNAL_IP=$1
    local KUBERNETES_PUB_IP=$2
    local ETCD_SERVERS_STR=$3
    
    sudo mkdir -p /etc/kubernetes/config
    
    chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl   
    sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
    
    sudo mkdir -p /var/lib/kubernetes/
    sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/
  
  
    cat > kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=${ETCD_SERVERS_STR} \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --runtime-config='api/all=true' \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-account-signing-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-account-issuer=https://${KUBERNETES_PUB_IP}:6443 \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    sudo mv kube-apiserver.service /etc/systemd/system/
   
    
    sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
    cat > kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    sudo mv kube-controller-manager.service /etc/systemd/system/


    sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
    cat > kube-scheduler.yaml <<EOF
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
    sudo mv kube-scheduler.yaml /etc/kubernetes/config/


    cat > kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    sudo mv kube-scheduler.service /etc/systemd/system/


    sudo systemctl daemon-reload
    sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
    sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}


for i in "${!CONTROLLERS[@]}" ; do
    ETCD_SERVERS_STR="${ETCD_SERVERS_STR},https://${CONTROLLERS_INT_IPS[$i]}:2379"
done
ETCD_SERVERS_STR=${ETCD_SERVERS_STR:1}
echo "${ETCD_SERVERS_STR}"

#pushd $BINARIES_DIR
#chmod +x kube-apiserver kube-controller-manager kube-scheduler
#popd

for i in "${!CONTROLLERS[@]}" ; do
    for file in kube-apiserver kube-controller-manager kube-scheduler kubectl ; do
       scp "${BINARIES_DIR}"/"$file" ${USER}@"${CONTROLLERS_EXT_IPS[$i]}":~/
       if [ $? -eq 0 ]; then
          echo "INFO: $file file to: ${CONTROLLERS[$i]} - ${CONTROLLERS_EXT_IPS[$i]} COPIED!"
       else
          echo "ERROR: $file file to: ${CONTROLLERS[$i]} - ${CONTROLLERS_EXT_IPS[$i]}"
       fi
    done
    
    ssh "${USER}"@"${CONTROLLERS_EXT_IPS[$i]}" << EOF
$(typeset -f control_bootstrap ${CONTROLLERS_INT_IPS[$i]} ${KUBERNETES_PUB_IP} ${ETCD_SERVERS_STR})
control_bootstrap ${CONTROLLERS_INT_IPS[$i]} ${KUBERNETES_PUB_IP} ${ETCD_SERVERS_STR}
EOF
done