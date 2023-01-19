#!/bin/bash
# Distribute the client and server certificates

source cluster-params.conf
cd $CERT_DIR

echo "You are here: ${CERT_DIR}"

for i in "${!WORKERS[@]}" ; do
    WORKER="${WORKERS[$i]}"
    for file in ca.pem "${WORKER}".pem "${WORKER}"-key.pem; do
       echo ${USER}@"${WORKERS_EXT_IPS[$i]}:~/"
       scp $file ${USER}@"${WORKERS_EXT_IPS[$i]}":~/ 
       if [ $? -eq 0 ]; then 
           echo "INFO: Certificates and private keys to  Worker instance: ${WORKER} - ${WORKERS_EXT_IPS[$i]} COPIED!"
       else
           echo "ERROR: Certificates and private keys to Worker instance: ${WORKER} - ${WORKERS_EXT_IPS[$i]}"
       fi
    done
done

for i in "${!CONTROLLERS[@]}" ; do
    CONTROLLER="${CONTROLLERS[$i]}"
    for file in ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem; do
       echo "${USER}@${CONTROLLERS_EXT_IPS[$i]}:~/"
       scp $file ${USER}@"${CONTROLLERS_EXT_IPS[$i]}":~/
       if [ $? -eq 0 ]; then
          echo "INFO: Certificates and private keys to Controller: ${CONTROLLER} - ${CONTROLLERS_EXT_IPS[$i]} COPIED!"
       else
          echo "ERROR: Certificates and private keys to Controller:  ${CONTROLLER} - ${CONTROLLERS_EXT_IPS[$i]}"
       fi
    done
done
