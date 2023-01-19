#!/bin/bash
cat <<"COMMENT"

In case you deploy Kubernetes cluster using Yandex Cloud compute instances. It's assumed that you have created network called 
kubernetes-the-hard-way with subnet kubernates and reserved Public IP (KUBERNETES_PUB_IP param in cluster-params.conf):
-----------------------------------------------------------------------------------------------------------------------------
source cluster-params.conf
yc load-balancer target-group create --name=kubernetes
GRP=$(yc load-balancer target-group get --name=kubernetes --format json | jq '.id' -r)
  
for i in 0 1 2; do
    yc load-balancer target-group add --name=kubernetes --target subnet-name=kubernetes,address=${CONTROLLERS_INT_IPS[i]}
done
  
yc load-balancer network-load-balancer create \
    --region-id ru-central1 \
    --name lb-1 \
    --listener name=listener,external-ip-version=ipv4,port=6443,target-port=6443,external-address=${KUBERNETES_PUB_IP} \
    --target-group target-group-id=${GRP},healthcheck-name=healthcheck,healthcheck-http-port=80,healthcheck-http-path=/healthz

------------------------------------------------------------------------------------------------------------------------------
Also an external load-balanced can be added by installing and configuring HAproxy package. This can make sense if it will be running on dedicated host.
An example of such a configuration can be found at: https://github.com/ecodelib/k8s-cluster-kubeadm

COMMENT