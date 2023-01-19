#!/bin/bash

source cluster-params.conf

# Deploy the DNS add-on using coredns-1.8.yaml downloaded from https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml

# You should have access to the registry containing coredns image.
# ----------------------------------------------------------------------------------------
# You can pull a default image, save it as .tar and load it to your local registry:
# $ docker pull coredns:1.8.3
# $ docker tag coredns:1.8.3 coredns-local:1.8.3
# $ docker save coredns:1.8.3 > coredns-local.tar
# $ docker load -i coredns-local.tar
# In that case edit .yaml file with image parameter and setting ImagePullPolicy to Never.
# ----------------------------------------------------------------------------------------

function deploy_coredns(){
    kubectl apply -f ${BINARIES_DIR}/coredns-1.8.yaml
    kubectl get pods -l k8s-app=kube-dns -n kube-system

    # Verify. Create a busybox deployment:
#    kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
#    kubectl get pods -l run=busybox
#    POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
#    kubectl exec -ti $POD_NAME -- nslookup kubernetes
}
    deploy_coredns