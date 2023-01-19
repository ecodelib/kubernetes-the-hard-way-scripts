#!/bin/bash

source cluster-params.conf


function rbac_kubelet() {
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
    if [ $? -eq 0 ]; then
        echo "***************************************************************************************"
        echo "          INFO: RBAC for Kubelet Authorization step 1 DONE!"
        echo "***************************************************************************************"
    fi

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
    if [ $? -eq 0 ]; then
        echo "***************************************************************************************"
        echo "          INFO: RBAC for Kubelet Authorization step 2 DONE!"
        echo "***************************************************************************************"
    fi
}

ssh "${USER}"@"${CONTROLLERS_EXT_IPS[0]}" << EOF
    $(typeset -f rbac_kubelet)
    rbac_kubelet
EOF