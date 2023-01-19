# Kubernetes The Hard Way with Scripts.
*This repo is a collection of scripts for a quick and an easy way of deploying Kubernetes HA cluster. Deployment process based on Kelsey Hightower's ["Kubernates the hard way"](https://github.com/kelseyhightower/kubernetes-the-hard-way) tutorial.*

## Prerequisites
1. You should provision compute resources as in [base tutorial](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md).
2. `cluster-params.conf` deployment configuration file to be updated according to your infrastructure.
3. You should have one K8s provisioner (host for provision cluster deployment). All the scripts should be executed from that host.

## Additional Info

1. Initially presented scripts were tested with Yandex Cloud platform services (Ubuntu VMs) consequently some files include extra info on deploying Kubernetes cluster using Yandex CLI.
2. Steps of downloading nginx, socat, conntrack and ipset binaries include downloading of their dependencies, therefore all packages required will be installed using pre-retrieved files and gdebi.

## Scripts to Deploy Kubernetes Cluster

### Download Binaries Necessary
`01-download-bins.sh`<br />
Script for downloading all the necessary binaries. Specify version in `cluster-params.conf` if needed.

### Install Provisioner's Tools
`02-install-client-tools.sh`<br />
Script for installing cfssl, cfssljson, kubectl on your provisioner host.


### Provision a CA, Generate and Distribute TSL Certificates
`03-ca-certs-generate.sh`<br />
`04-distribute-cert.sh`<br />
Provision PKI Infra and then bootstrap a CA, generate TLS certs for etcd, kube-apiserver, kube-controller-manager, kube-scheduler, kubelet, kube-proxy.  

### Generate and Distribute Configuration Files for Authentication
`05-config-auth-generate.sh`<br />
`06-distribute-config.sh`<br />
Generate Kubernetes kubeconfigs which allow K8s clients to locate and authenticate to K8s API servers.

### Generate and distribute Data Encryption Config and Key
`07-data-encrypt-conf.sh`<br />
Generate a key and a config for encrypting Kubernetes Secrets.

### Bootstrap the etcd Cluster
`08-etcd-bootstrap.sh`<br />
Bootstrap and configure etcd HA cluster.

### Bootstrap Control Plane
`09-control-plane-bootstrap.sh`<br />
Bootstrap K8s control plane across provided compute instances.

### Enable HTTP Health Checks
`10-nginx-health.sh`<br />
Nginx web server accepts HTTP health checks on port 80 and proxy connections to the API server on https://127.0.0.1:6443/healthz.

### Configure RBAC Permissions
`11-rbac-for-kubelet.sh`<br />
RBAC permissions for K8s API Server to access the Kubelet API on each worker node.

### The Kubernetes Frontend Load Balancer
`12-network-load-balancer.sh`<br />
In case you deploy k8s cluster on Yandex Cloud platform follow these steps using Yandex Cloud CLI.


### Bootstrap Worker Nodes
`13-worker-nodes-bootstrap.sh`<br />
Bootstrap worker nodes. Install runc, container networking plugins, containerd, kubelet, kube-proxy on each worker node.

### Configuring kubectl for Remote Access
`14-kubectl-remote-config.sh`<br />
Generate kubeconfig file for kubectl CLI based on the admin user credentials.

### Provision Pod Network Routes
`15-pod-network-routes.sh`<br />
Pods will be able to communicate with other pods running on different nodes using network routes. For instance if you use Yandex Cloud platform follow the steps provided using Yandex Cloud CLI. 15-pod-network-routes.sh provided as an example of automatic network routes setup.

### Deploying the DNS Cluster Add-on
`16-dns-cluster-addon-bootstrap.sh`<br />
Deploy the DNS add-on for DNS based service discovery inside the K8s cluster.

### Smoke Test
`17-smoke-test.sh`<br />
To test newly created cluster follow the steps described in [this lab](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/1.7.4/docs/13-smoke-test.md).