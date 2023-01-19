#!/bin/bash

# Change directory to binaries dir
eval $(grep -i BINARIES_DIR $(pwd)/cluster-params.conf)
cd $BINARIES_DIR

# Install client tools
chmod +x cfssl cfssljson kubectl
sudo cp cfssl cfssljson /usr/local/bin/
sudo cp kubectl /usr/local/bin/

# Check versions

echo "cfssl version:"
cfssl version
echo

echo "cfssljson version:"
cfssljson --version
echo

echo "kubectl version:"
kubectl version --client
echo
