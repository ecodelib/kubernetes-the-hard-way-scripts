#!/bin/bash

source cluster-params.conf


rm -f -r ${ENCRYPT_CONF_DIR}
mkdir -p ${ENCRYPT_CONF_DIR}

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > ${ENCRYPT_CONF_DIR}/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

cd ${ENCRYPT_CONF_DIR}

for i in "${!CONTROLLERS[@]}" ; do
    CONTROLLER="${CONTROLLERS[$i]}"
       scp encryption-config.yaml ${USER}@"${CONTROLLERS_EXT_IPS[$i]}":~/
       if [ $? -eq 0 ]; then
          echo "INFO: Encryption-config.yaml config file to: ${CONTROLLER} - ${CONTROLLERS_EXT_IPS[$i]} COPIED!"
       else
          echo "ERROR: Encryption-config.yaml config file to: ${CONTROLLER} - ${CONTROLLERS_EXT_IPS[$i]}"
       fi
done