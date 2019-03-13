oldip=$(cat /etc/oldip)
newip=$(ip addr show ens4 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
#
## replace ip in configuration
find /etc/kubernetes -type f | xargs sed -i "s/$oldip/$newip/"
find /root/.kube -type f | xargs sed -i "s/$oldip/$newip/"

rm /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.key
kubeadm alpha phase certs apiserver

rm /etc/kubernetes/pki/etcd/peer.crt /etc/kubernetes/pki/etcd/peer.key
kubeadm alpha phase certs etcd-peer

systemctl restart kubelet

kubectl -n kube-system get cm kube-proxy -o yaml  | sed 's/$oldip/$newip/' | kubectl apply -f -
kubectl -n kube-system get cm kubeadm-config -o yaml  | sed 's/$oldip/$newip/' | kubectl apply -f -

systemctl restart docker kubelet
