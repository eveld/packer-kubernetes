#!/bin/sh
trap "clear; exec /bin/bash;" INT TERM

if ! curl --silent --fail --output /dev/null http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/; then
  echo "Starting Kubernetes, this may take a minute or so"
  while ! curl --silent --fail --output /dev/null http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/; do printf "." && sleep 1; done || break
  printf "done."
  echo ""
fi
clear
kubectl get secret -o json -n kube-system $(kubectl get secret -n kube-system | grep kubernetes-dashboard-token | awk '{ print $1 }') | jq -r '.data.token' | base64 --decode > /root/dashboard-token.txt
echo ""
echo "Your Kubernetes cluster is ready. Use this token to access the Kubernetes Dashboard:"
echo ""
cat /root/dashboard-token.txt
echo ""
echo ""
echo "Copy/paste with Ctrl-Insert/Shift-Insert"
echo ""
exec /bin/bash
