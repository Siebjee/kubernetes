#!/bin/bash
# source bin/update_hosts.sh
cd "$(dirname $0)/../"

function setup_flux {
  echo "Setting up flux"
  kubectl apply -n flux-system -f flux/install.yaml
  kubectl apply -n flux-system -f k8s/infrastructure/git-repositories/playground.yaml
}

function setup_kustomize {
  echo "Setting up kustomize"
  local cluster=$1
  kubectl apply -n flux-system -f k8s/clusters/${cluster}/configuration.yaml
}

function setup_harbor {
  echo "Setting up harbor"
  ./bin/setup_harbor.sh

  HARBOR_CERTS=$(kubectl --namespace harbor get secret harbor-harbor-ingress -o jsonpath="{.data}" | jq -r)
  cat <<YAML | kubectl --namespace flux-system apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: harbor-tls-certs
  namespace: flux-system
type: Opaque
data:
  caFile: $(echo ${HARBOR_CERTS} | jq -r ".\"ca.crt\"")
  certFile: $(echo ${HARBOR_CERTS} | jq -r ".\"tls.crt\"")
  keyFile: $(echo ${HARBOR_CERTS} | jq -r ".\"tls.key\"")
  username: ZGVtbw==
  password: RGVtb2RlbW8w
YAML

}

function setup_ci_keys {
  echo "Setting up ci keys"

  keyFile="${HOME}/.ssh/ci_key_rsa"
  if [ ! -e ${keyFile} ]; then
    cat /dev/zero | ssh-keygen -t rsa -b 4096 -f ${keyFile} -q -C "ci_key_rsa" -N ""
  fi

  kubectl delete -n flux-system secret ci-key-rsa 2> /dev/null
  kubectl create -n flux-system secret generic ci-key-rsa \
    --from-file=identity=${keyFile} \
    --from-file=identity.pub=${keyFile}.pub \
    --from-file=known_hosts=<(ssh-keyscan github.com 2> /dev/null)

  kubectl delete -n argo secret ci-key-rsa 2> /dev/null
  kubectl create -n argo secret generic ci-key-rsa \
    --from-file=identity=${keyFile} \
    --from-file=identity.pub=${keyFile}.pub \
    --from-file=known_hosts=<(ssh-keyscan github.com 2> /dev/null)
}

function setup_regcreds {
  echo "Setting up docker registry credentials"

  for namespace in $(kubectl get namespaces -o=jsonpath='{.items[*].metadata.name}'); do
    kubectl delete secret regcred 2> /dev/null \
    kubectl create secret docker-registry regcred \
      --docker-server=harbor.k8s-local.io \
      --docker-username=demo \
      --docker-password=Demodemo0 \
      --docker-email=demo@k8s-local.io \
      --namespace ${namespace}
  done
}

function setup_minio {
  ./bin/setup_minio.sh
}

function setup_demo {
  echo "Setting up cluster ${cluster}"
  setup_flux
  setup_kustomize demo
  setup_ci_keys
  echo "Going to sleep before finalizing MinIO and Harbor"
  for i in {120..1}; do
    echo -ne "\rsleeping ${i}..."
    sleep 1
  done
  setup_harbor
  setup_minio
}

setup_demo

source ./bin/update_hosts.sh
source ./bin/secrets.sh
