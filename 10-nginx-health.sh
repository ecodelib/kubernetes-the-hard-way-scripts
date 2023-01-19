#!/bin/bash

source cluster-params.conf


function bootstrap_nginx(){
    cd nginx
    sudo dpkg -i gdebi-core*.deb
#    sudo cp -R ./*.deb /var/cache/apt/archives/
    sudo yes | sudo gdebi nginx_*
    cd -
    
    
    cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

    sudo mv kubernetes.default.svc.cluster.local \
      /etc/nginx/sites-available/kubernetes.default.svc.cluster.local
 
    sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    sudo systemctl enable nginx
  
    kubectl cluster-info --kubeconfig admin.kubeconfig
    curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz   
}
  
cd $BINARIES_DIR/nginx/
for i in "${!CONTROLLERS[@]}" ; do

    ssh "${USER}"@"${CONTROLLERS_EXT_IPS[$i]}" "mkdir nginx"
    for file in * ; do
        scp "$file" ${USER}@"${CONTROLLERS_EXT_IPS[$i]}":~/nginx
    done

    ssh "${USER}"@"${CONTROLLERS_EXT_IPS[$i]}" << EOF
        $(typeset -f bootstrap_nginx)
        bootstrap_nginx
EOF
done