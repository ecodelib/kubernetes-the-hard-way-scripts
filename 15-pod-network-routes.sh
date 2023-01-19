#!/bin/bash

# Pods scheduled to a node receive an address from the node's Pod CIDR range. Create routes in the kubernetes-the-hard-way VPC network.
cat <<"COMMENT"

In case of depoling Kubernetes cluster using Yandex Cloud services:
-----------------------------------------------------------------------------------------------
source cluster-params.conf

# adding routes
ROUTE=()
for i in 0 1 2; do
     ROUTE+=(--route destination=10.200.${i}.0/24, next-hop=${WORKERS_INT_IPS[i]})
done
yc vpc route-table create --name=kube-routes --network-name=kubernetes-the-hard-way ${ROUTE[@]}
yc vpc route-table get kube-routes
yc vpc subnet update kubernetes --route-table-name kube-routes
-----------------------------------------------------------------------------------------------

COMMENT
