#!/bin/sh
keyFile="${HOME}/.ssh/ci_key_rsa.pub"

kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$nTC/9KwY3k9yQRxON5MfYuQGEdHBs62sg4PqWyDHAfavFfS/vKPa6",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

echo "[Dashboard]"
echo "  Kubernetes dashboard token:"
kubectl get secret -n kube-system | grep k8sadmin | cut -d " " -f1 | xargs -n 1 | xargs kubectl get secret  -o 'jsonpath={.data.token}' -n kube-system | base64 --decode
echo ""
echo "[Flux]"
echo "  Flux public key:"
cat ${keyFile}
echo "[Grafana]"
echo "  Graphana username: admin"
echo "  Graphana password: $(kubectl get secret --namespace monitoring loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
echo ""
echo "[Harbor]"
echo "  Admin user: admin"
echo "  Password: IbwvebaSuhhN5J5vCKqeJAj85eufb3"
echo ""
echo "[MinIO]"
echo "  JWT: $(kubectl get secret $(kubectl get serviceaccount console-sa --namespace minio -o jsonpath="{.secrets[0].name}") --namespace minio -o jsonpath="{.data.token}" | base64 --decode)"
