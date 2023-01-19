#!/bin/bash

source cluster-params.conf

function bootstrap_the_etcd(){
    local INTERNAL_IP=$1
    local INIT_CLUSTER_STR=$2
    local ETCD_VER=$3
   
    tar -xvf etcd-v"${ETCD_VER}"-linux-amd64.tar.gz
    sudo mv etcd-v"${ETCD_VER}"-linux-amd64/etcd* /usr/local/bin/
    
    sudo mkdir -p /etc/etcd /var/lib/etcd
    sudo chmod 700 /var/lib/etcd
    sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
    
    ETCD_NAME=$(hostname -s)
    echo "**************${ETCD_NAME} Getting info***************"
    
    cat > etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${INIT_CLUSTER_STR} \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    sudo mv etcd.service /etc/systemd/system/
    if [ $? -eq 0 ]; then 
        echo "***1. MOVED: etcd.service to /etc/systemd/system/"
    fi
    
    sudo systemctl daemon-reload
    if [ $? -eq 0 ]; then
        echo "***2. RELOADED: systemctl daemon"
    fi
    
    sudo systemctl enable etcd
    if [ $? -eq 0 ]; then
        echo "***3. ENABLED: systemctl enable etcd"
    fi
    
    sudo systemctl start etcd
    if [ $? -eq 0 ]; then
        echo "***4. STARTED: systemctl etcd"
    fi
    
    sudo ETCDCTL_API=3 etcdctl member list \
       --endpoints=https://127.0.0.1:2379 \
       --cacert=/etc/etcd/ca.pem \
       --cert=/etc/etcd/kubernetes.pem \
       --key=/etc/etcd/kubernetes-key.pem
    if [ $? -eq 0 ]; then
        echo "***5. RECIEVED: etcdctl member list "  
    fi
    
    rm -rf etcd.sh etcd-v"${ETCD_VER}"-linux-amd64.tar.gz etcd-v"${ETCD_VER}"-linux-amd64/
    if [ $? -eq 0 ]; then
        echo "***6. REMOVED: etcd.sh etcd-v"${ETCD_VER}"-linux-amd64.tar.gz etcd-v"${ETCD_VER}"-linux-amd64/"  
    fi    
}

for i in "${!CONTROLLERS[@]}" ; do
    INIT_CLUSTER_STR="${INIT_CLUSTER_STR},${CONTROLLERS[$i]}=https://${CONTROLLERS_INT_IPS[$i]}:2380"
done
INIT_CLUSTER_STR=${INIT_CLUSTER_STR:1}
echo "${INIT_CLUSTER_STR}"


ETCD_FILE="etcd-v${ETCD_VER}-linux-amd64.tar.gz"

for i in "${!CONTROLLERS[@]}" ; do   
       scp "${BINARIES_DIR}"/"${ETCD_FILE}" "${USER}"@"${CONTROLLERS_EXT_IPS[$i]}":~/
       if [ $? -eq 0 ]; then
          echo "INFO: ${ETCD_FILE} file to: ${CONTROLLERS[$i]} - ${CONTROLLERS_EXT_IPS[$i]} COPIED!"
       else
          echo "ERROR:  ${ETCD_FILE} file to: ${CONTROLLERS[$i]} - ${CONTROLLERS_EXT_IPS[$i]}"
       fi
       
       ssh "${USER}"@"${CONTROLLERS_EXT_IPS[$i]}" << EOF
$(typeset -f bootstrap_the_etcd ${CONTROLLERS_INT_IPS[$i]} ${INIT_CLUSTER_STR} ${ETCD_VER})
bootstrap_the_etcd ${CONTROLLERS_INT_IPS[$i]} ${INIT_CLUSTER_STR} ${ETCD_VER}
EOF
done