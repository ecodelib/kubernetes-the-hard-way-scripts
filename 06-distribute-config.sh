#!/bin/bash
# Distribute the client and server certificates

source cluster-params.conf
cd ${KUBE_CONF_DIR}


echo "You are here: ${KUBE_CONF_DIR}"

for i in "${!WORKERS[@]}" ; do
    WORKER=${WORKERS[$i]}
    for file in ${WORKER}.kubeconfig kube-proxy.kubeconfig ; do
       
       scp $file ${USER}@"${WORKERS_EXT_IPS[$i]}":~/ 
       if [ $? -eq 0 ]; then 
           echo "INFO: Kubelet and kube-proxy kubeconfig files to: ${WORKER} - ${WORKERS_EXT_IPS[$i]} COPIED!"
       else
           echo "ERROR: ubelet and kube-proxy kubeconfig files to: ${WORKER} - ${WORKERS_EXT_IPS[$i]}"
       fi
    done
done

for i in "${!CONTROLLERS[@]}" ; do
    CONTROLLER="${CONTROLLERS[$i]}"
    for file in admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ; do
       scp $file ${USER}@"${CONTROLLERS_EXT_IPS[$i]}":~/
       if [ $? -eq 0 ]; then
          echo "INFO: Kube-controller-manager and kube-scheduler kubeconfig files to: ${CONTROLLER} - ${CONTROLLERS_EXT_IPS[$i]} COPIED!"
       else
          echo "ERROR: Kube-controller-manager and kube-scheduler kubeconfig files to:  ${CONTROLLER} - ${CONTROLLERS_EXT_IPS[$i]}"
       fi
    done
done
