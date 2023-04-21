#!/usr/bin/env bash
KUBE_INTERNAL=172.31.255.254
sudo ifconfig lo0 alias ${KUBE_INTERNAL}

INGRESSES=$(kubectl get ingress --all-namespaces -o jsonpath='{.items[*].spec.rules[*].host}')
LOCALHOST=${KUBE_INTERNAL}

HOST_FILE=/etc/hosts
HOSTS_ENTRY="${LOCALHOST} ${INGRESSES}"

if grep -Fq "${KUBE_INTERNAL}" ${HOST_FILE} > /dev/null; then
  sudo sed -i -e "s/^.* ${KUBE_INTERNAL}.*/${HOSTS_ENTRY}/" ${HOST_FILE}
else
  sudo echo "${KUBE_INTERNAL} placeholder.k8s-local.io" >> ${HOST_FILE}
fi
