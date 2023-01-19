#! /bin/bash

# File with cluster params:
source cluster-params.conf

rm -f -r ${CERT_DIR}
mkdir -p ${CERT_DIR}


# Generate Certificate Authority and copy the result to cert's derictory.
if cfssl gencert -initca ${JSON_DIR}/ca-csr.json | cfssljson -bare ca ; then
    mv ca.pem ca-key.pem ca.csr ${CERT_DIR}
    echo "***************************************************************************************"
    echo "                    INFO: Generate Certificate Authority DONE!"
    echo "***************************************************************************************"
else
    echo "E R R O R :  Generating Certificate Authority"
fi

# The Admin Client Certificate and The Kubelet Client Certificates genaration.
if cfssl gencert \
       -ca=${CERT_DIR}/ca.pem \
       -ca-key=${CERT_DIR}/ca-key.pem \
       -config=${JSON_DIR}/ca-config.json \
       -profile=kubernetes \
       ${JSON_DIR}/admin-csr.json | cfssljson -bare admin ; then
    mv admin.pem admin-key.pem admin.csr ${CERT_DIR}
    echo "***************************************************************************************"
    echo "                INFO: The Admin Client Certificate genaration DONE!"
    echo "***************************************************************************************"
else
    echo " E R R O R  : The Admin Client Certificate genaration"
fi


for i in "${!WORKERS[@]}"; do
   WORKER=${WORKERS[$i]}
   export WORKER=${WORKERS[$i]}
   envsubst < $JSON_DIR/worker-csr.json > $JSON_DIR/"${WORKERS[$i]}"-csr.json
   if cfssl gencert \
         -ca=${CERT_DIR}/ca.pem \
         -ca-key=${CERT_DIR}/ca-key.pem \
         -config=${JSON_DIR}/ca-config.json \
         -hostname="${WORKERS[$i]}","${WORKERS_EXT_IPS[$i]}","${WORKERS_INT_IPS[$i]}" \
         -profile=kubernetes \
         $JSON_DIR/"${WORKERS[$i]}"-csr.json | cfssljson -bare "${WORKERS[i]}" ; then
        mv "${WORKERS[$i]}"-key.pem "${WORKERS[i]}".pem "${WORKERS[$i]}".csr ${CERT_DIR}
        echo "
        ***************************************************************************************"
        echo "           INFO: The Kubelet Client Certificates #${i} genaration DONE!"
        echo "***************************************************************************************"
    else
        echo "E R R O R : The Kubelet Client Certificates #${i} genarations"
    fi
    rm ${JSON_DIR}/"${WORKERS[$i]}"-csr.json
done

# Generate The Controller Manager Client Certificate And The Private Key.
if cfssl gencert \
      -ca=${CERT_DIR}/ca.pem \
      -ca-key=${CERT_DIR}/ca-key.pem \
      -config=${JSON_DIR}/ca-config.json \
      -profile=kubernetes \
      ${JSON_DIR}/kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager ; then
    mv kube-controller-manager.pem kube-controller-manager.csr kube-controller-manager-key.pem ${CERT_DIR}
    echo "***************************************************************************************"
    echo " INFO:The Controller Manager Client Certificate And The Private Key generation DONE!"
    echo "***************************************************************************************"
else
    echo "E R R O R : Generating The Controller Manager Client Certificate And The Private Key"
fi

# Generate the kube-proxy client certificate and private key.
if cfssl gencert \
      -ca=${CERT_DIR}/ca.pem \
      -ca-key=${CERT_DIR}/ca-key.pem \
      -config=${JSON_DIR}/ca-config.json \
      -profile=kubernetes \
      ${JSON_DIR}/kube-proxy-csr.json | cfssljson -bare kube-proxy ; then
    mv kube-proxy.pem kube-proxy.csr kube-proxy-key.pem ${CERT_DIR}
    echo "***************************************************************************************"
    echo "     INFO: Generate the kube-proxy client certificate and private key DONE!"
    echo "***************************************************************************************"
else
    echo "E R R O R : Generating The Kube-proxy Client Certificate And Private Key"
fi

# The Scheduler Client Certificate.
if cfssl gencert \
      -ca=${CERT_DIR}/ca.pem \
      -ca-key=${CERT_DIR}/ca-key.pem \
      -config=${JSON_DIR}/ca-config.json \
      -profile=kubernetes \
      ${JSON_DIR}/kube-scheduler-csr.json | cfssljson -bare kube-scheduler ; then
    mv kube-scheduler.pem kube-scheduler.csr kube-scheduler-key.pem ${CERT_DIR}
    echo "***************************************************************************************"
    echo "          INFO: The Scheduler Client Certificate and private key DONE!"
    echo "***************************************************************************************"
else
    echo "E R R O R : Generating The Scheduler Client Certificate "
fi

# Generate The Kubernetes API Server Certificate.
INT_IPS_STRING=""

for CONTROLLER_IP in "${CONTROLLERS_INT_IPS[@]}"; do
    INT_IPS_STRING="${INT_IPS_STRING},${CONTROLLER_IP}"
done

INT_IPS_STRING=${INT_IPS_STRING:1}
echo
echo "${INT_IPS_STRING}"
echo

if cfssl gencert \
      -ca=${CERT_DIR}/ca.pem \
      -ca-key=${CERT_DIR}/ca-key.pem \
      -config=${JSON_DIR}/ca-config.json \
      -hostname=10.32.0.1,${INT_IPS_STRING},${KUBERNETES_PUB_IP},127.0.0.1,${KUBERNETES_HOSTNAMES} \
      -profile=kubernetes \
      ${JSON_DIR}/kubernetes-csr.json | cfssljson -bare kubernetes ; then
    mv kubernetes-key.pem kubernetes.csr kubernetes.pem ${CERT_DIR}
    echo "***************************************************************************************"
    echo "          INFO: Generate The Kubernetes API Server Certificate DONE!"
    echo "***************************************************************************************"
else
    echo "E R R O R : Generating The Kubernetes API Server Certificate "
fi

# Generate the Service Account key pair.
if cfssl gencert \
      -ca=certificates/ca.pem \
      -ca-key=certificates/ca-key.pem \
      -config=${JSON_DIR}/ca-config.json \
      -profile=kubernetes \
      ${JSON_DIR}/service-account-csr.json | cfssljson -bare service-account ; then
    mv service-account-key.pem service-account.csr service-account.pem ${CERT_DIR}
    echo "***************************************************************************************"
    echo "             INFO: Generate the Service Account key pair DONE!"
    echo "***************************************************************************************"
else
    echo "E R R O R : Generating the Service Account key pair"
fi
