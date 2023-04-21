#!/usr/bin/env bash
set -eou pipefail

KUBEVAL_BIN="${1:?'Please provide the kubeval binary path as arg 1'}"
K8S_BASE="${2:?'Please provide the base directory as arg 2'}"
export YAMLLINT_CONFIG_FILE=${K8S_BASE}/.yamllint.yaml

K8S_BASE=${K8S_BASE}/k8s
K8S_VERSION="v1.19.13"

KUBEVAL_ARGS="--exit-on-error --ignore-missing-schemas -${K8S_VERSION} -s https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master"

envs="base demo cloud"
overlays="apps ci core"


if ! command yamllint --version; then
  pip install --user yamllint
fi

function printTest {
  cat << EOF

##########
# Testing $1
##########

EOF
}

printTest "Testing yaml format"
python3 -m yamllint ${K8S_BASE}

for env in ${envs}; do
  (
    for overlay in ${overlays}; do
      if ! test -d ${K8S_BASE}/${overlay}/${env}; then continue; fi
      cd ${K8S_BASE}/${overlay}/${env}
      for app in $(ls); do
        printTest "${overlay}/${env}/${app}"
        cd ${K8S_BASE}/${overlay}/${env}/${app}
        set -x
        kustomize build | ${KUBEVAL_BIN} ${KUBEVAL_ARGS} -
        set +x
      done
    done
  )
done

(
  cd ${K8S_BASE}/infrastructure/
  for component in $(ls); do
    (
      printTest "infrastructure/${component}"
      cd ${K8S_BASE}/infrastructure/${component}
      ${KUBEVAL_BIN} ${KUBEVAL_ARGS} ${K8S_BASE}/infrastructure/${component}/*.yaml
    )
  done
)

cat << EOF
Done !
EOF
