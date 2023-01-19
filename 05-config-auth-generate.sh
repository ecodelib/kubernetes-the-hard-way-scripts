#!/bin/bash

source cluster-params.conf



rm -f -r ${KUBE_CONF_DIR}
mkdir -p ${KUBE_CONF_DIR}

function conf-gen(){
    local INSTANCE=$1
    local USER=$2
    local SERVER=$3
        
    kubectl config set-cluster ${CLUSTER} \
        --certificate-authority=${CERT_DIR}/ca.pem \
        --embed-certs=true \
        --server=https://${SERVER}:6443 \
        --kubeconfig=${KUBE_CONF_DIR}/${INSTANCE}.kubeconfig

    kubectl config set-credentials ${USER} \
        --client-certificate=${CERT_DIR}/${INSTANCE}.pem \
        --client-key=${CERT_DIR}/${INSTANCE}-key.pem \
        --embed-certs=true \
        --kubeconfig=${KUBE_CONF_DIR}/${INSTANCE}.kubeconfig

    kubectl config set-context default \
        --cluster=${CLUSTER} \
        --user=${USER} \
        --kubeconfig=${KUBE_CONF_DIR}/${INSTANCE}.kubeconfig

    kubectl config use-context default --kubeconfig=${KUBE_CONF_DIR}/${INSTANCE}.kubeconfig
}

for WORKER in "${WORKERS[@]}" ; do
conf-gen ${WORKER} system:node:${WORKER} ${KUBERNETES_PUB_IP}
    echo "***************************************************************************************"
    echo "      INFO: Generations of the kubeconfig file for worker node: ${WORKER} DONE!"
    echo "***************************************************************************************"
done

conf-gen kube-proxy system:kube-proxy ${KUBERNETES_PUB_IP}
if [ $? -eq 0 ]; then
    echo "***************************************************************************************" 
    echo "       INFO: The kube-proxy Configuration File - generation DONE!"
    echo "***************************************************************************************"
fi

conf-gen kube-controller-manager system:kube-controller-manager 127.0.0.1
if [ $? -eq 0 ]; then
    echo "***************************************************************************************" 
    echo "   INFO: Generate a kubeconfig file for the kube-controller-manager service DONE!"
    echo "***************************************************************************************"
fi

conf-gen kube-scheduler system:kube-scheduler 127.0.0.1
if [ $? -eq 0 ]; then
    echo "***************************************************************************************" 
    echo "          INFO: The kube-scheduler Kubernetes Configuration File DONE!"
    echo "***************************************************************************************"
fi

conf-gen admin admin 127.0.0.1
if [ $? -eq 0 ]; then
    echo "***************************************************************************************" 
    echo "              INFO: The admin Kubernetes Configuration File DONE!"
    echo "***************************************************************************************"
fi